import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../audio.dart';
import '../common.dart';
import '../data.dart';
import '../field.dart';
import '../shell.dart';
import '../theme.dart';

/// SCENE 3 — hold to speak.
///
/// The floor of the whole product is spoken testimony (D3), so the recording
/// surface has to feel like something is listening, not like a progress bar is
/// filling. A row of bars says "measurement". A closed contour that winds your
/// last 2.3 seconds of voice around a circle says "this is being taken in".
///
/// What is on screen, back to front:
///   · a particle field of 96 motes, pushed outward by amplitude
///   · three amplitude contours built from the rolling history, phase-offset,
///     so the shape rotates as you speak and your syllables wind around it
///   · onset ripples, emitted on level peaks
///   · the elapsed clock in the middle
///
/// All of it is one CustomPainter repainting off the engine. No widget in this
/// subtree rebuilds while you are holding except a one-per-second clock label.
///
/// Motion class demonstrated: sustained real-time data visualisation at vsync.
class SpeakScene extends StatefulWidget {
  const SpeakScene({super.key, required this.cue, required this.field});

  final SceneCue cue;
  final FieldController field;

  @override
  State<SpeakScene> createState() => _SpeakSceneState();
}

class _SpeakSceneState extends State<SpeakScene>
    with SingleTickerProviderStateMixin {
  final _engine = SpeechEngine();
  late final Ticker _ticker = createTicker(_tick);
  final _seconds = ValueNotifier<int>(0);
  final _source = ValueNotifier<AmpSource>(AmpSource.idle);
  final _transcript = ValueNotifier<bool>(false);

  Duration _last = Duration.zero;
  Timer? _reveal;
  Timer? _auto;
  bool _autoHeld = false;

  @override
  void initState() {
    super.initState();
    widget.cue.addListener(_onCue);
    _ticker.start();
    if (widget.cue.active) _onCue();
  }

  void _tick(Duration now) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : (now - _last).inMicroseconds / 1e6;
    _last = now;
    _engine.tick(dt.clamp(0.0, 1 / 20));

    final s = _engine.elapsed.inSeconds;
    if (s != _seconds.value) _seconds.value = s;
    if (_engine.source != _source.value) _source.value = _engine.source;

    if (widget.cue.active) {
      // The field swells with the voice. One number, shared across the whole
      // app — this is why the background lives in the shell and not in here.
      widget.field.targetBreath = _engine.level * _engine.presence;
    }
  }

  void _onCue() {
    if (!mounted) return;
    if (widget.cue.active) {
      widget.field
        ..targetIntensity = 0.72
        ..targetFocus = const Offset(0.5, 0.47);
      _reset();
      if (kAutoDrive) _startAuto();
      if (kPose) {
        Timer(const Duration(milliseconds: 600), () {
          if (mounted && widget.cue.active) _begin();
        });
      }
    } else {
      _auto?.cancel();
      _auto = null;
      _end();
      widget.field.targetBreath = 0;
    }
  }

  void _startAuto() {
    _auto?.cancel();
    _autoHeld = false;
    // 3.5 s held, 2.5 s released, forever. Exercises start/stop of the mic
    // stream as well as the visualisation itself.
    _auto = Timer.periodic(const Duration(milliseconds: 500), (t) {
      if (!mounted || !widget.cue.active) return;
      final phase = (t.tick * 500) % 6000;
      if (phase == 0 && !_autoHeld) {
        _autoHeld = true;
        _begin();
      } else if (phase >= 3500 && _autoHeld) {
        _autoHeld = false;
        _end();
      }
    });
  }

  void _reset() {
    _reveal?.cancel();
    _transcript.value = false;
    _engine.reset();
    _seconds.value = 0;
  }

  void _begin() {
    if (_engine.running) return;
    _reset();
    _engine.start();
  }

  void _end() {
    if (!_engine.running) return;
    _engine.stop();
    _reveal?.cancel();
    _reveal = Timer(const Duration(milliseconds: 520), () {
      if (mounted) _transcript.value = true;
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _reveal?.cancel();
    widget.cue.removeListener(_onCue);
    _ticker.dispose();
    _engine.dispose();
    _seconds.dispose();
    _source.dispose();
    _transcript.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScenePad(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EyebrowRow('tonight', '60–90 seconds'),
          const SizedBox(height: 26),
          Text(kMorningLead, style: Face.micro),
          const SizedBox(height: 4),
          Text(kMorningQuote, style: Face.body.copyWith(color: Palette.ash)),
          const Spacer(),
          Center(
            child: Listener(
              onPointerDown: (_) => _begin(),
              onPointerUp: (_) => _end(),
              onPointerCancel: (_) => _end(),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 300,
                height: 300,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _VoicePainter(_engine),
                    isComplex: true,
                    willChange: true,
                    child: Center(child: _centre()),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          SizedBox(height: scaled(context, 104), child: _transcriptBlock()),
          const SizedBox(height: 8),
          Center(child: _sourceLabel()),
        ],
      ),
    );
  }

  Widget _centre() {
    return ValueListenableBuilder<int>(
      valueListenable: _seconds,
      builder: (context, s, _) {
        return AnimatedBuilder(
          animation: _engine,
          builder: (context, _) {
            final p = _engine.presence;
            return Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: (1 - p * 2.2).clamp(0.0, 1.0),
                  child: Text('HOLD TO SPEAK', style: Face.button),
                ),
                Opacity(
                  opacity: ((p - 0.25) * 1.8).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.9 + 0.1 * p,
                    child: Text(
                      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}',
                      style: Face.numeral.copyWith(
                        color: Color.lerp(
                          Palette.inkContainer,
                          Palette.ink,
                          _engine.level,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _transcriptBlock() {
    return ValueListenableBuilder<bool>(
      valueListenable: _transcript,
      builder: (context, on, _) => AnimatedOpacity(
        opacity: on ? 1 : 0,
        duration: const Duration(milliseconds: 520),
        curve: Motion.ease,
        child: AnimatedSlide(
          offset: on ? Offset.zero : const Offset(0, 0.14),
          duration: const Duration(milliseconds: 620),
          curve: Motion.ease,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('you said', style: Face.micro),
              const SizedBox(height: 5),
              Text(kTranscript, style: Face.body.copyWith(color: Palette.ash)),
            ],
          ),
        ),
      ),
    );
  }

  /// Honesty line. Says out loud whether the shape you are watching is your
  /// voice or a model of one.
  Widget _sourceLabel() {
    return ValueListenableBuilder<AmpSource>(
      valueListenable: _source,
      builder: (context, s, _) {
        final text = switch (s) {
          AmpSource.microphone => 'signal · live microphone',
          AmpSource.synthesised => 'signal · synthesised envelope'
              '${_engine.micError == null ? '' : ' (mic: ${_engine.micError})'}',
          AmpSource.idle => 'signal · idle',
        };
        return Text(
          text,
          style: Face.micro,
          textAlign: TextAlign.center,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
class _VoicePainter extends CustomPainter {
  _VoicePainter(this.e) : super(repaint: e);

  final SpeechEngine e;

  static const _n = SpeechEngine.historyLength;

  /// Scratch buffers. Allocated once at class scope; the paint loop must not
  /// allocate, or the GC will find you at 120 Hz.
  static final Float32List _smooth = Float32List(_n);
  static final Float32List _px = Float32List(_n);
  static final Float32List _py = Float32List(_n);
  static final ui.Path _path = ui.Path();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final base = size.shortestSide * 0.295; // ~88 at 300
    final p = e.presence;
    final lvl = e.level;
    final paint = Paint()..isAntiAlias = true;

    // 3-tap circular smoothing of the history, so the contour is a curve and
    // not a sawtooth.
    final head = e.head;
    for (var j = 0; j < _n; j++) {
      final i0 = (head - j + _n) % _n;
      final im = (i0 - 1 + _n) % _n;
      final ip = (i0 + 1) % _n;
      _smooth[j] =
          0.25 * e.history[im] + 0.5 * e.history[i0] + 0.25 * e.history[ip];
    }

    _particles(canvas, c, base, p, lvl, paint);
    _ripples(canvas, c, base, p, paint);

    // Three contours. The phase offset between them is what gives the shape
    // depth — the outer rings are showing you slightly older audio.
    for (var k = 2; k >= 0; k--) {
      final radius = base * (1 + k * 0.115);
      final amp = base * (0.46 - k * 0.10) * (0.25 + 0.75 * p);
      final phase = k * 9;
      final alpha = (k == 0 ? 0.95 : (k == 1 ? 0.42 : 0.20)) *
          (0.30 + 0.70 * p);

      _buildContour(c, radius, amp, phase);

      if (k == 0) {
        // Body: a dark fill so the type in the middle always has something to
        // sit on, and the contour reads as an object rather than a line.
        paint
          ..style = PaintingStyle.fill
          ..shader = ui.Gradient.radial(c, radius * 1.15, [
            Palette.containerLow.withValues(alpha: 0.85),
            Palette.base.withValues(alpha: 0.22),
          ], const [0.0, 1.0]);
        canvas.drawPath(_path, paint);
        paint.shader = null;
      }

      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = k == 0 ? 1.5 : 1.0
        ..color = Color.lerp(Palette.stone, Palette.ink, lvl * 0.85)!
            .withValues(alpha: alpha);
      canvas.drawPath(_path, paint);
    }
  }

  /// Builds a closed contour into the shared [_path]. Catmull-Rom would be
  /// smoother; with 168 points around a 90 px circle the segments are under
  /// 3.4 px, so straight lines are already sub-pixel and cost a third as much.
  void _buildContour(Offset c, double radius, double amp, int phase) {
    for (var j = 0; j < _n; j++) {
      final a = -math.pi / 2 + (j / _n) * math.pi * 2;
      final s = _smooth[(j + phase) % _n];
      final r = radius + amp * s;
      _px[j] = c.dx + math.cos(a) * r;
      _py[j] = c.dy + math.sin(a) * r;
    }
    _path.reset();
    _path.moveTo(_px[0], _py[0]);
    for (var j = 1; j < _n; j++) {
      _path.lineTo(_px[j], _py[j]);
    }
    _path.close();
  }

  void _particles(
    Canvas canvas,
    Offset c,
    double base,
    double p,
    double lvl,
    Paint paint,
  ) {
    paint
      ..style = PaintingStyle.fill
      ..shader = null;
    final gain = 0.24 + 0.76 * p;
    for (var i = 0; i < SpeechEngine.particleCount; i++) {
      final a = e.particleAngle(i);
      final rr = base * (0.78 + e.particleRadius(i) * 0.52);
      final twinkle = 0.55 + 0.45 * math.sin(e.particlePhase(i));
      final alpha = (0.05 + 0.40 * lvl) * gain * twinkle;
      if (alpha < 0.012) continue;
      paint.color = Color.lerp(Palette.stone, Palette.inkContainer, lvl)!
          .withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(
        Offset(c.dx + math.cos(a) * rr, c.dy + math.sin(a) * rr),
        e.particleSize(i) * (0.55 + 0.45 * lvl),
        paint,
      );
    }
  }

  void _ripples(Canvas canvas, Offset c, double base, double p, Paint paint) {
    paint
      ..style = PaintingStyle.stroke
      ..shader = null;
    for (var i = 0; i < SpeechEngine.rippleCount; i++) {
      if (!e.rippleLive(i)) continue;
      final age = e.rippleAge(i) / 2.4;
      final r = base * (0.98 + age * 0.85);
      final a = (1 - age) * (1 - age) * e.rippleStrength(i) * 0.34 * p;
      if (a < 0.008) continue;
      paint
        ..strokeWidth = 1.0 * (1 - age * 0.6)
        ..color = Palette.stone.withValues(alpha: a);
      canvas.drawCircle(c, r, paint);
    }
  }

  @override
  bool shouldRepaint(_VoicePainter old) => false;
}
