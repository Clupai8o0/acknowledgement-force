import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

/// `--dart-define=SYNTH=1` forces the synthesised envelope even when a working
/// microphone is present. Used for the captures and for the memory soak, where
/// a silent room would make the visualisation look broken rather than quiet.
const kForceSynth = bool.fromEnvironment('SYNTH');

/// Where the amplitude in scene 3 is coming from. Shown on screen, because a
/// demo that fakes its input without saying so is a lie with nice easing.
enum AmpSource {
  /// Real PCM off the device/host microphone, RMS'd per buffer.
  microphone,

  /// Synthesised speech envelope. Used when the mic is unavailable or denied.
  synthesised,

  /// Not started.
  idle,
}

/// The speech engine.
///
/// Owns the amplitude signal, the rolling history the radial waveform is drawn
/// from, and the particle/ripple state. Everything here is fixed-capacity and
/// mutated in place: no per-frame allocation, because this is the one surface
/// in the app that runs flat out for 60 seconds at a time.
class SpeechEngine extends ChangeNotifier {
  SpeechEngine() {
    for (var i = 0; i < particleCount; i++) {
      _pAngle[i] = _rng.nextDouble() * math.pi * 2;
      _pSpin[i] = (_rng.nextDouble() - 0.5) * 0.28;
      _pRadius[i] = 0.55 + _rng.nextDouble() * 0.72;
      _pPhase[i] = _rng.nextDouble() * math.pi * 2;
      _pSize[i] = 0.7 + _rng.nextDouble() * 1.5;
      _pDrift[i] = 0.4 + _rng.nextDouble() * 1.2;
    }
  }

  static const historyLength = 168;
  static const particleCount = 96;
  static const rippleCount = 12;
  static const _sampleHz = 72.0;

  final _rng = math.Random(7);

  // --- signal --------------------------------------------------------------
  final Float32List history = Float32List(historyLength);
  int _head = 0;
  int get head => _head;

  double _raw = 0; // latest value from the source
  double _level = 0; // smoothed, what everything reads
  double _peak = 0; // slow-decay peak, drives the ripples
  double get level => _level;
  double get peak => _peak;

  bool _running = false;
  bool get running => _running;
  AmpSource source = AmpSource.idle;
  String? micError;

  Duration elapsed = Duration.zero;

  /// 0 while idle, ramps to 1 while held. Everything visual multiplies by this
  /// so the collapse on release is one number, not fifteen.
  double presence = 0;

  // --- particles (structure-of-arrays; no objects in the hot loop) ----------
  final _pAngle = Float32List(particleCount);
  final _pSpin = Float32List(particleCount);
  final _pRadius = Float32List(particleCount);
  final _pPhase = Float32List(particleCount);
  final _pSize = Float32List(particleCount);
  final _pDrift = Float32List(particleCount);
  final _pPush = Float32List(particleCount);

  double particleAngle(int i) => _pAngle[i];
  double particleRadius(int i) => _pRadius[i] + _pPush[i];
  double particleSize(int i) => _pSize[i];
  double particlePhase(int i) => _pPhase[i];

  // --- ripples -------------------------------------------------------------
  final _rAge = Float32List(rippleCount);
  final _rLive = Uint8List(rippleCount);
  final _rStrength = Float32List(rippleCount);
  bool rippleLive(int i) => _rLive[i] == 1;
  double rippleAge(int i) => _rAge[i];
  double rippleStrength(int i) => _rStrength[i];

  double _sampleAcc = 0;
  double _synthClock = 0;
  double _syllableAt = 0;
  double _syllableLen = 0;
  double _syllableGain = 0;
  double _breathUntil = 0;
  double _rippleCooldown = 0;

  AudioRecorder? _rec;
  StreamSubscription<Uint8List>? _sub;

  // -------------------------------------------------------------------------
  Future<void> start() async {
    if (_running) return;
    _running = true;
    elapsed = Duration.zero;
    _synthClock = 0;
    _syllableAt = 0;
    source = AmpSource.synthesised; // until the mic proves itself
    notifyListeners();
    if (!kForceSynth) unawaited(_tryMic());
  }

  Future<void> _tryMic() async {
    try {
      final rec = _rec ??= AudioRecorder();
      if (!await rec.hasPermission()) {
        micError = 'permission denied';
        return;
      }
      if (!_running) return;
      final stream = await rec.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          echoCancel: false,
          noiseSuppress: false,
        ),
      );
      if (!_running) {
        await rec.stop();
        return;
      }
      _sub = stream.listen(
        _onPcm,
        onError: (Object e) {
          micError = '$e';
          source = AmpSource.synthesised;
        },
        cancelOnError: false,
      );
    } catch (e) {
      micError = '$e';
      source = AmpSource.synthesised;
      debugPrint('[speech] mic unavailable ($e) — using synthesised envelope');
    }
  }

  int _silentBuffers = 0;

  void _onPcm(Uint8List bytes) {
    if (!_running) return;
    // RMS over the buffer, in place. 16-bit LE mono.
    final n = bytes.lengthInBytes ~/ 2;
    if (n == 0) return;
    final view = ByteData.sublistView(bytes);
    var sum = 0.0;
    // Stride if the buffer is fat; 512 samples is plenty for an envelope.
    final stride = n > 1024 ? n ~/ 512 : 1;
    var count = 0;
    for (var i = 0; i < n; i += stride) {
      final s = view.getInt16(i * 2, Endian.little) / 32768.0;
      sum += s * s;
      count++;
    }
    final rms = math.sqrt(sum / count);

    // A dead simulator mic returns exact silence forever. Detect that and fall
    // back rather than showing a flat line and calling it "real audio".
    if (rms < 1e-5) {
      if (++_silentBuffers > 40 && source == AmpSource.microphone) {
        source = AmpSource.synthesised;
        micError = 'mic open but silent';
      }
    } else {
      _silentBuffers = 0;
      source = AmpSource.microphone;
      micError = null;
    }

    if (source != AmpSource.microphone) return;
    // dBFS -> 0..1, floor at -52 dB which is about where a quiet room sits.
    final db = 20 * (math.log(rms.clamp(1e-6, 1.0)) / math.ln10);
    _raw = ((db + 58) / 54).clamp(0.0, 1.0);
    // Perceptual shaping: speech spends most of its life in the bottom third.
    _raw = math.pow(_raw, 0.62).toDouble();
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _raw = 0;
    final sub = _sub;
    _sub = null;
    await sub?.cancel();
    try {
      if (await _rec?.isRecording() ?? false) await _rec?.stop();
    } catch (_) {}
    notifyListeners();
  }

  // --- the frame loop ------------------------------------------------------
  void tick(double dt) {
    if (_running) elapsed += Duration(microseconds: (dt * 1e6).round());

    if (_running && source != AmpSource.microphone) _synthesise(dt);
    if (!_running) _raw = 0;

    // Attack fast, release slow. This asymmetry is most of why a meter reads as
    // "voice" rather than "noise".
    final rate = _raw > _level ? 26.0 : 8.5;
    _level += (_raw - _level) * (1 - math.exp(-rate * dt));
    _peak = math.max(_peak - dt * 1.15, _level);

    presence += ((_running ? 1.0 : 0.0) - presence) *
        (1 - math.exp(-(_running ? 7.0 : 4.0) * dt));

    // History advances on its own clock so the waveform's spatial frequency is
    // identical at 60 and 120 Hz.
    _sampleAcc += dt;
    final step = 1 / _sampleHz;
    var guard = 0;
    while (_sampleAcc >= step && guard++ < 8) {
      _sampleAcc -= step;
      _head = (_head + 1) % historyLength;
      history[_head] = _level;
    }

    _tickParticles(dt);
    _tickRipples(dt);
    notifyListeners();
  }

  void _tickParticles(double dt) {
    final l = _level;
    for (var i = 0; i < particleCount; i++) {
      _pAngle[i] += _pSpin[i] * dt * (0.35 + l * 1.5);
      if (_pAngle[i] > math.pi * 2) _pAngle[i] -= math.pi * 2;
      if (_pAngle[i] < 0) _pAngle[i] += math.pi * 2;
      final want = l * _pDrift[i] * 0.55;
      _pPush[i] += (want - _pPush[i]) * (1 - math.exp(-4.5 * dt));
      _pPhase[i] += dt * (0.7 + _pDrift[i] * 0.5);
    }
  }

  void _tickRipples(double dt) {
    _rippleCooldown -= dt;
    for (var i = 0; i < rippleCount; i++) {
      if (_rLive[i] == 0) continue;
      _rAge[i] += dt;
      if (_rAge[i] > 2.4) _rLive[i] = 0;
    }
    // Emit on an onset: level crossing well above the recent floor.
    if (_running && _rippleCooldown <= 0 && _level > 0.34 && _level >= _peak - 0.02) {
      for (var i = 0; i < rippleCount; i++) {
        if (_rLive[i] == 0) {
          _rLive[i] = 1;
          _rAge[i] = 0;
          _rStrength[i] = _level;
          _rippleCooldown = 0.26;
          break;
        }
      }
    }
  }

  /// A synthesised speech envelope: syllables of 90–220 ms at a 3.5–6 Hz rate,
  /// grouped into phrases with breath pauses, plus a little jitter. It is not a
  /// sine wave and it is not random noise — both of those read as fake
  /// instantly. This is what a meter looks like when someone is actually
  /// talking.
  void _synthesise(double dt) {
    _synthClock += dt;
    if (_synthClock >= _breathUntil && _synthClock >= _syllableAt + _syllableLen) {
      // Next syllable, or a breath.
      if (_rng.nextDouble() < 0.14) {
        _breathUntil = _synthClock + 0.28 + _rng.nextDouble() * 0.55;
        _syllableGain = 0;
      } else {
        _syllableAt = _synthClock;
        _syllableLen = 0.09 + _rng.nextDouble() * 0.13;
        _syllableGain = 0.34 + _rng.nextDouble() * 0.62;
        // Occasional stressed syllable.
        if (_rng.nextDouble() < 0.16) _syllableGain = math.min(1, _syllableGain * 1.45);
      }
    }
    if (_synthClock < _breathUntil) {
      _raw = 0.03 + _rng.nextDouble() * 0.02;
      return;
    }
    final u = ((_synthClock - _syllableAt) / _syllableLen).clamp(0.0, 1.0);
    // Asymmetric syllable envelope: sharp attack, softer decay.
    final env = u < 0.22
        ? math.pow(u / 0.22, 0.55).toDouble()
        : math.pow(1 - (u - 0.22) / 0.78, 1.6).toDouble();
    _raw = (_syllableGain * env + 0.035 + _rng.nextDouble() * 0.03).clamp(0.0, 1.0);
  }

  void reset() {
    for (var i = 0; i < historyLength; i++) {
      history[i] = 0;
    }
    for (var i = 0; i < rippleCount; i++) {
      _rLive[i] = 0;
    }
    _level = 0;
    _peak = 0;
    _raw = 0;
    elapsed = Duration.zero;
  }

  @override
  void dispose() {
    _running = false;
    _sub?.cancel();
    _sub = null;
    _rec?.dispose();
    _rec = null;
    super.dispose();
  }
}
