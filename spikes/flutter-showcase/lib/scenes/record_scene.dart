import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../common.dart';
import '../data.dart';
import '../field.dart';
import '../shell.dart';
import '../theme.dart';

/// SCENE 2 — the record strip.
///
/// Seven days, three states (D7). The entrance is not a curve pretending to be
/// physics: each mark is an actual [SpringSimulation] sampled analytically at
/// its own staggered time offset, so the overshoot is a consequence of mass and
/// stiffness rather than a number I tuned by eye.
///
/// Tapping a mark expands it. The expansion spring is retargetable mid-flight —
/// tap a second day while the first is still opening and the panel does not
/// restart, it redirects.
///
/// Motion class demonstrated: staggered spring entrance, retargetable
/// expansion, painter-driven strip with zero widget rebuilds.
class RecordScene extends StatefulWidget {
  const RecordScene({super.key, required this.cue, required this.field});

  final SceneCue cue;
  final FieldController field;

  @override
  State<RecordScene> createState() => _RecordSceneState();
}

class _RecordSceneState extends State<RecordScene>
    with SingleTickerProviderStateMixin {
  late final _model = _StripModel();
  late final Ticker _ticker = createTicker(_tick);
  final _selected = ValueNotifier<int>(-1);
  Duration _last = Duration.zero;
  Timer? _auto;

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
    _model.advance(dt.clamp(0.0, 1 / 20));
  }

  void _onCue() {
    if (!mounted) return;
    if (widget.cue.active) {
      widget.field
        ..targetIntensity = 0.5
        ..targetFocus = const Offset(0.5, 0.34)
        ..targetBreath = 0;
      _model.replayEntrance();
      _select(-1);
      if (kPose) {
        Timer(const Duration(milliseconds: 1400), () {
          if (mounted && widget.cue.active) _select(1);
        });
      }
      if (kAutoDrive) {
        _auto?.cancel();
        var i = 0;
        _auto = Timer.periodic(const Duration(milliseconds: 1300), (_) {
          if (!mounted || !widget.cue.active) return;
          i++;
          _select(i % 8 == 7 ? -1 : i % kRecord.length);
        });
      }
    } else {
      _auto?.cancel();
      _auto = null;
    }
  }

  void _select(int i) {
    final next = _selected.value == i ? -1 : i;
    _selected.value = next;
    _model.selectedIndex = next;
    _model.reveal.retarget(next < 0 ? 0 : 1);
  }

  @override
  void dispose() {
    _auto?.cancel();
    widget.cue.removeListener(_onCue);
    _ticker.dispose();
    _selected.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScenePad(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EyebrowRow('the record', 'last 7 days'),
          const Spacer(flex: 2),
          // The strip. A row of tap targets over one painter — the painter is
          // the only thing that repaints, and it repaints off the model, so a
          // 120 Hz spring costs zero framework rebuilds.
          SizedBox(
            height: 96,
            child: LayoutBuilder(
              builder: (context, box) {
                final slot = box.maxWidth / kRecord.length;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _StripPainter(_model),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                    for (var i = 0; i < kRecord.length; i++)
                      Positioned(
                        left: slot * i,
                        top: 0,
                        width: slot,
                        height: 96,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _select(i),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 30),
          // Fixed so selecting a day never nudges the strip. The panel is the
          // thing that moves; the record stays exactly where it was.
          SizedBox(height: scaled(context, 250), child: _detail()),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _detail() {
    return ValueListenableBuilder<int>(
      valueListenable: _selected,
      builder: (context, idx, _) {
        final content = idx < 0
            ? const _Prompt(key: ValueKey('prompt'))
            : _DayDetail(day: kRecord[idx], key: ValueKey(idx));
        return AnimatedBuilder(
          animation: _model,
          builder: (context, _) {
            final r = _model.reveal.value.clamp(-0.15, 1.15);
            return Align(
              alignment: Alignment.topLeft,
              child: Transform.translate(
                offset: Offset(0, 14 * (1 - r)),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Motion.ease,
                  switchOutCurve: Motion.easeIn,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: Transform.translate(
                      offset: Offset(0, 8 * (1 - a.value)),
                      child: child,
                    ),
                  ),
                  child: content,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('a day is kept, broken, or unsettled.', style: Face.title),
        const SizedBox(height: 12),
        Text(
          'unsettled is not broken. broken means you showed up and lost. '
          'tap a day.',
          style: Face.meta,
        ),
      ],
    );
  }
}

class _DayDetail extends StatelessWidget {
  const _DayDetail({super.key, required this.day});

  final Day day;

  static const _verdict = {
    Mark.kept: 'kept',
    Mark.broken: 'broken',
    Mark.unsettled: 'unsettled',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(day.label),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MarkDot(mark: day.mark, size: 11),
            const SizedBox(width: 11),
            Text(
              _verdict[day.mark]!,
              style: Face.title.copyWith(
                color: day.mark == Mark.kept ? Palette.ink : Palette.mute,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          day.mark == Mark.unsettled
              ? 'you did not answer. one is noise. two in a row changes '
                  'what this app does.'
              : day.testimony,
          style: Face.body.copyWith(
            color: day.mark == Mark.unsettled
                ? Palette.mute
                : Palette.inkContainer,
          ),
        ),
        if (day.tempo != null) ...[
          const SizedBox(height: 18),
          const SizedBox(width: 48, child: DrawnRule(t: 1)),
          const SizedBox(height: 10),
          Text(day.tempo!, style: Face.micro),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
class _StripModel extends ChangeNotifier {
  static const _entrySpring =
      SpringDescription(mass: 1, stiffness: 165, damping: 17);

  final entry = SpringSimulation(_entrySpring, 0, 1, 0);
  final reveal = Spring1D(
    value: 0,
    spring: const SpringDescription(mass: 1, stiffness: 210, damping: 24),
  );

  /// Per-mark scale springs — the selected one grows, the rest do not.
  late final List<Spring1D> grow = List.generate(
    kRecord.length,
    (_) => Spring1D(
      value: 0,
      spring: const SpringDescription(mass: 1, stiffness: 250, damping: 20),
    ),
  );

  double _t = 0;
  int _selectedIndex = -1;
  int get selectedIndex => _selectedIndex;
  set selectedIndex(int v) {
    if (v == _selectedIndex) return;
    _selectedIndex = v;
    for (var i = 0; i < grow.length; i++) {
      grow[i].retarget(i == v ? 1 : 0);
    }
  }

  /// Entrance progress of mark [i], sampled from a real spring at its own
  /// staggered start time.
  double entryOf(int i) {
    final local = _t - i * 0.052;
    if (local <= 0) return 0;
    return entry.x(local);
  }

  double get t => _t;

  void replayEntrance() {
    _t = 0;
    for (final g in grow) {
      g.reset(0);
    }
    reveal.reset(0);
    _selectedIndex = -1;
  }

  void advance(double dt) {
    _t += dt;
    reveal.advance(dt);
    for (final g in grow) {
      g.advance(dt);
    }
    notifyListeners();
  }
}

class _StripPainter extends CustomPainter {
  _StripPainter(this.m) : super(repaint: m);

  final _StripModel m;

  @override
  void paint(Canvas canvas, Size size) {
    final n = kRecord.length;
    final slot = size.width / n;
    final baseY = 34.0;
    final p = Paint()..isAntiAlias = true;
    // The strip is NOT dimmed on selection. `broken` is filled `stone`, which
    // measures 3.03:1 against base — exactly the non-text minimum — so any
    // knock-down at all puts it under. Selection is carried by the halo and by
    // size instead, neither of which costs contrast.
    const dim = 1.0;

    // The connecting hairline. It draws in with the marks and stops where they
    // stop — it is the spine the record hangs on, not a chart axis.
    final e0 = m.entryOf(0).clamp(0.0, 1.0);
    final eN = m.entryOf(n - 1).clamp(0.0, 1.0);
    final x0 = slot * 0.5, x1 = slot * (n - 0.5);
    if (e0 > 0.01) {
      p
        ..color = Palette.outlineSoft.withValues(alpha: 0.9 * dim)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(x0, baseY),
        Offset(x0 + (x1 - x0) * (0.35 * e0 + 0.65 * eN).clamp(0.0, 1.0), baseY),
        p,
      );
    }

    for (var i = 0; i < n; i++) {
      final day = kRecord[i];
      final e = m.entryOf(i);
      if (e <= 0.001) continue;
      final ec = e.clamp(0.0, 1.3);
      final g = m.grow[i].value;
      final selected = m.selectedIndex == i;
      final today = i == n - 1;

      final cx = slot * (i + 0.5);
      final cy = baseY + 22 * (1 - ec);
      final alpha = (e * 1.15).clamp(0.0, 1.0) * (selected ? 1.0 : dim);
      final r = 5.0 * (0.45 + 0.55 * ec) * (1 + 0.62 * g);

      // Selection halo — a ring that expands and thins as it settles.
      if (g > 0.004) {
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Palette.bright.withValues(alpha: 0.55 * g.clamp(0.0, 1.0));
        canvas.drawCircle(Offset(cx, cy), r + 8 + 6 * (1 - g.clamp(0.0, 1.0)), p);
      }

      // Today gets a soft outer breath so the strip has a "now" without a
      // second colour.
      if (today && !selected) {
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Palette.outlineSoft.withValues(alpha: 0.75 * alpha);
        canvas.drawCircle(Offset(cx, cy), r + 6, p);
      }

      p.style = PaintingStyle.fill;
      switch (day.mark) {
        case Mark.kept:
          p.color = Palette.ink.withValues(alpha: alpha);
          canvas.drawCircle(Offset(cx, cy), r, p);
        case Mark.broken:
          p.color = Palette.stone.withValues(alpha: alpha);
          canvas.drawCircle(Offset(cx, cy), r, p);
        case Mark.unsettled:
          p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            // Hollow, and in `mute` rather than `outline`: it has to read as
            // an absence you can see, not as a rendering artefact. A 1.6 px
            // ring at 1.7:1 is invisible on a dark phone at night.
            ..color = Palette.mute.withValues(alpha: alpha);
          canvas.drawCircle(Offset(cx, cy), math.max(r - 0.7, 0.5), p);
      }

      // Day letter, quietly.
      // Floor of 0.78: the day letters are text, and text does not get to be
      // a texture.
      _letter(canvas, day.label.substring(0, 1), cx, baseY + 28,
          alpha * (0.78 + 0.22 * g.clamp(0.0, 1.0)));
    }
  }

  /// Alpha is quantised to 16 steps and the laid-out TextPainter cached per
  /// (letter, step). Seven letters means the cache tops out at 112 entries and
  /// then never grows — bounded, so it is a cache and not a leak. The naive
  /// alternatives both cost more than they look: a saveLayer per letter is 7
  /// offscreen passes a frame, and re-laying out the span every frame is 7
  /// text layouts a frame at 120 Hz.
  static final _lp = <int, TextPainter>{};

  void _letter(Canvas canvas, String s, double cx, double y, double alpha) {
    if (alpha <= 0.02) return;
    final step = (alpha.clamp(0.0, 1.0) * 15).round();
    final key = s.codeUnitAt(0) * 16 + step;
    final tp = _lp.putIfAbsent(
      key,
      () => TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: Face.ui_,
            fontSize: 14,
            letterSpacing: 1.8,
            color: Palette.mute.withValues(alpha: step / 15),
            fontVariations: v(500, 14),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
    );
    tp.paint(canvas, Offset(cx - tp.width / 2, y));
  }

  @override
  bool shouldRepaint(_StripPainter old) => false;
}
