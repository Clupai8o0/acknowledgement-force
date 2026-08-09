import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:record/record.dart';

/// Live microphone amplitude as a 40-slot scrolling ring buffer.
///
/// Two clocks, on purpose:
///   • `record`'s PCM stream delivers buffers at the hardware IO rate and only
///     updates `_raw`;
///   • a Ticker shifts the ring at a fixed 60 columns/second so the scroll
///     speed is independent of both buffer size and display refresh rate
///     (this Mac's panel may be 120 Hz; the Swift build ticks at 60).
///
/// This is a [Listenable] rather than a state object: the meter is painted by a
/// CustomPainter that takes it as `repaint`, so a tick repaints one RenderObject
/// and never rebuilds a widget.
class AudioMeter extends ChangeNotifier {
  static const int barCount = 40;
  static const double _columnHz = 60;
  static const double _dbFloor = 55; // -55 dBFS reads as silence

  /// Newest sample is the LAST element (right-hand end of the meter).
  final Float32List levels = Float32List(barCount);

  Duration elapsed = Duration.zero;

  /// Non-null when the mic was refused or no input device could be opened.
  String? failure;

  final AudioRecorder _recorder = AudioRecorder();
  late final Ticker _ticker = Ticker(_onTick);
  StreamSubscription<Uint8List>? _sub;

  double _raw = 0; // newest normalised RMS, written from the audio stream
  double _smoothed = 0;
  double _carryMs = 0;
  Duration _lastTick = Duration.zero;

  bool get running => _ticker.isActive;

  Future<void> start() async {
    if (running) return;
    levels.fillRange(0, barCount, 0);
    _raw = 0;
    _smoothed = 0;
    _carryMs = 0;
    _lastTick = Duration.zero;
    elapsed = Duration.zero;
    failure = null;
    // The meter goes live on the first frame; audio joins it once granted, so
    // the permission round-trip never stalls the animation.
    _ticker.start();
    notifyListeners();

    try {
      if (!await _recorder.hasPermission()) {
        failure = 'microphone refused';
        stdout.writeln('AUDIO refused');
        notifyListeners();
        return;
      }
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          // 48 kHz on purpose: it is the built-in mic's native rate, so
          // record_macos' AVAudioConverter does no sample-rate conversion.
          // Asking for 44.1 kHz makes the converter error out after a few
          // seconds, and record_macos treats that as "stop recording" without
          // telling Dart — the stream just goes silent mid-hold.
          sampleRate: 48000,
          numChannels: 1,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
          // Ignored on macOS: AVAudioEngine hands out whatever the HAL gives
          // (~4096 frames here, so ~11 amplitude updates/second). The meter
          // scrolls on its own 60 Hz clock precisely because of this.
          streamBufferSize: 512,
        ),
      );
      _sub = stream.listen(
        _onChunk,
        onError: (Object e) {
          failure = '$e';
          stdout.writeln('AUDIO error $e');
        },
      );
    } catch (e) {
      failure = '$e';
      stdout.writeln('AUDIO failed $e');
      notifyListeners();
    }
  }

  Future<void> stop() async {
    if (_ticker.isActive) _ticker.stop();
    await _sub?.cancel();
    _sub = null;
    _raw = 0;
    if (await _recorder.isRecording()) await _recorder.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _sub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  // --- audio thread side ---------------------------------------------------

  void _onChunk(Uint8List bytes) {
    final n = bytes.lengthInBytes ~/ 2;
    if (n == 0) return;
    final data = ByteData.sublistView(bytes);
    var sum = 0.0;
    for (var i = 0; i < n; i++) {
      final s = data.getInt16(i * 2, Endian.little) / 32768.0;
      sum += s * s;
    }
    final rms = math.sqrt(sum / n);
    final db = 20 * (math.log(math.max(rms, 1e-7)) / math.ln10);
    _raw = ((db + _dbFloor) / _dbFloor).clamp(0.0, 1.0);
    _chunks++;
    if (_diag && !_sawAudio) {
      _sawAudio = true;
      stdout.writeln('AUDIO live: $n samples/buffer, level=${_raw.toStringAsFixed(3)}');
    }
  }

  static final bool _diag = Platform.environment['GATE_FRAMES'] != null;
  bool _sawAudio = false;
  int _diagShifts = 0;
  int _chunks = 0;

  // --- 60 columns/second ring shift ---------------------------------------

  void _onTick(Duration now) {
    elapsed = now;
    final deltaMs = (now - _lastTick).inMicroseconds / 1000.0;
    _lastTick = now;
    _carryMs += deltaMs;

    const stepMs = 1000 / _columnHz;
    var shifts = 0;
    while (_carryMs >= stepMs && shifts < 4) {
      _carryMs -= stepMs;
      shifts++;
      // Fast attack, slow release — makes speech read as speech, not as noise.
      final k = _raw > _smoothed ? 0.55 : 0.14;
      _smoothed += (_raw - _smoothed) * k;
      for (var i = 0; i < barCount - 1; i++) {
        levels[i] = levels[i + 1];
      }
      levels[barCount - 1] = _smoothed.clamp(0.0, 1.0);
    }
    if (_carryMs > stepMs) _carryMs = 0; // dropped frames: don't bank a backlog
    if (_diag) {
      _diagShifts += shifts;
      if (_diagShifts >= 60) {
        _diagShifts = 0;
        stdout.writeln(
          'AUDIO level raw=${_raw.toStringAsFixed(3)} '
          'smoothed=${_smoothed.toStringAsFixed(3)} chunks/s=$_chunks',
        );
        _chunks = 0;
      }
    }
    notifyListeners();
  }
}
