import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

// ---------------------------------------------------------------------------
// Spring1D — the workhorse behind every "interruptible" claim in this app.
//
// Flutter's AnimationController.animateWith(SpringSimulation) is fine until you
// need to *retarget mid-flight*, which is the whole point of using springs. So
// this keeps its own clock and, on retarget, rebuilds the simulation seeded
// with the current position AND the current velocity. That is the difference
// between a spring and a curve pretending to be one: the mark you flung at
// KEPT keeps its momentum when you change your mind and hit BROKEN.
// ---------------------------------------------------------------------------
class Spring1D {
  Spring1D({
    required double value,
    this.spring = const SpringDescription(mass: 1, stiffness: 190, damping: 22),
  }) : _target = value,
       _sim = ScrollSpringSimulation(
         const SpringDescription(mass: 1, stiffness: 190, damping: 22),
         value,
         value,
         0,
       ),
       _t = 0;

  final SpringDescription spring;
  Simulation _sim;
  double _t;
  double _target;

  double get value => _sim.x(_t);
  double get velocity => _sim.dx(_t);
  double get target => _target;
  bool get settled => _sim.isDone(_t);

  void advance(double dt) => _t += dt;

  /// Retarget without discontinuity. Position and velocity carry over exactly.
  void retarget(double to, {double? velocity}) {
    final v = velocity ?? this.velocity;
    final x = value;
    _target = to;
    _t = 0;
    _sim = SpringSimulation(spring, x, to, v);
  }

  /// Hard set — no motion, used when a scene resets.
  void reset(double to) {
    _target = to;
    _t = 0;
    _sim = SpringSimulation(spring, to, to, 0);
  }
}

// ---------------------------------------------------------------------------
// Blur-in type.
//
// Per-word ImageFilter.blur means a saveLayer per word — ~14 offscreen passes
// for one sentence, which is exactly how you lose 120 Hz. Instead this renders
// the glyphs as their own drop shadow: transparent fill, Shadow(blurRadius: b,
// offset: zero). Same optical result, no layer, and it degrades to a plain
// crisp glyph at b == 0. This trick is the single most useful thing I learned
// building this.
// ---------------------------------------------------------------------------
class BlurText extends StatelessWidget {
  const BlurText(
    this.text, {
    super.key,
    required this.style,
    required this.t,
    this.rise = 16,
    this.maxBlur = 10,
    this.textAlign,
  });

  final String text;
  final TextStyle style;

  /// 0 = absent, 1 = arrived.
  final double t;
  final double rise;
  final double maxBlur;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final e = t.clamp(0.0, 1.0);
    final blur = maxBlur * (1 - e) * (1 - e);
    final dy = rise * (1 - e);
    final color = style.color ?? Palette.ink;

    final Widget child;
    if (blur < 0.12) {
      child = Text(
        text,
        textAlign: textAlign,
        style: style.copyWith(color: color.withValues(alpha: e)),
      );
    } else {
      child = Text(
        text,
        textAlign: textAlign,
        style: style.copyWith(
          color: const Color(0x00000000),
          shadows: [
            Shadow(
              color: color.withValues(alpha: e),
              blurRadius: blur,
            ),
          ],
        ),
      );
    }
    return Transform.translate(offset: Offset(0, dy), child: child);
  }
}

/// Stagger helper: the sub-progress of item [i] of [n] within [t], where each
/// item's window is [span] of the whole and starts are evenly spread.
double stagger(double t, int i, int n, {double span = 0.55, Curve? curve}) {
  if (n <= 1) return (curve ?? Motion.ease).transform(t.clamp(0.0, 1.0));
  final start = (1 - span) * (i / (n - 1));
  final local = ((t - start) / span).clamp(0.0, 1.0);
  return (curve ?? Motion.ease).transform(local);
}

// ---------------------------------------------------------------------------
// The record mark.
// kept = filled ink · broken = filled stone · unsettled = hollow ring
// (FORCE-V2 §D7 — unsettled is NOT broken, and the shapes must not imply it is.)
// ---------------------------------------------------------------------------
class MarkDot extends StatelessWidget {
  const MarkDot({
    super.key,
    required this.mark,
    this.size = Metrics.markSize,
    this.opacity = 1,
    this.today = false,
  });

  final Mark? mark;
  final double size;
  final double opacity;
  final bool today;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        size: Size.square(size),
        painter: MarkPainter(mark: mark, today: today),
      ),
    );
  }
}

class MarkPainter extends CustomPainter {
  const MarkPainter({required this.mark, this.today = false, this.scale = 1});

  final Mark? mark;
  final bool today;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 * scale;
    final p = Paint()..isAntiAlias = true;
    switch (mark) {
      case Mark.kept:
        canvas.drawCircle(c, r, p..color = Palette.ink);
      case Mark.broken:
        canvas.drawCircle(c, r, p..color = Palette.stone);
      case Mark.unsettled:
        canvas.drawCircle(
          c,
          r - 0.7,
          p
            ..color = Palette.mute
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      case null:
        canvas.drawCircle(
          c,
          r - 0.7,
          p
            ..color = today ? Palette.mute : Palette.bright
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
    }
  }

  @override
  bool shouldRepaint(MarkPainter old) =>
      old.mark != mark || old.today != today || old.scale != scale;
}

// ---------------------------------------------------------------------------
// Press feedback. No Material, so this is the whole button system: a scale and
// an opacity, spring-backed, interruptible. 0.97 not 0.9 — this is an app about
// self-accountability, not a game.
// ---------------------------------------------------------------------------
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.965,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final HitTestBehavior behavior;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) => _c.reverse(),
      onTapCancel: () => _c.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.scale(
          scale: 1 - (1 - widget.scale) * Motion.ease.transform(_c.value),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// A hairline that draws itself. Used as a beat between sections — cheaper on
/// the eye than another block of type.
class DrawnRule extends StatelessWidget {
  const DrawnRule({
    super.key,
    required this.t,
    this.color = Palette.outlineSoft,
    this.width = double.infinity,
  });

  final double t;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: t.clamp(0.0, 1.0),
        child: Container(height: 1, width: width, color: color),
      ),
    );
  }
}

/// Section eyebrow: `NIGHT 19 · 28-DAY PURSUIT` etc.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.t = 1, this.color, this.align});

  final String text;
  final double t;

  /// Kept for the rare emphasised eyebrow. `stone` is not a legal value —
  /// see the note on [Face]; anything passed here must clear 4.5:1 on base.
  final Color? color;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Text(
        text.toUpperCase(),
        textAlign: align,
        style: color == null ? Face.label : Face.label.copyWith(color: color),
      ),
    );
  }
}

/// Every scene sits in the same box: safe-area top, 30 pt gutters, and 62 pt
/// held back at the bottom for the indicator. Consistency here is what stops
/// six scenes reading as six apps.
class ScenePad extends StatelessWidget {
  const ScenePad({super.key, required this.child, this.horizontal = Metrics.gutter});

  final Widget child;
  final double horizontal;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontal,
        pad.top + 18,
        horizontal,
        pad.bottom + scaled(context, 74),
      ),
      child: child,
    );
  }
}

/// Scale a reserved height by the OS text-size setting. Anywhere this app
/// holds space open for text that has not arrived yet, it holds *scaled*
/// space — otherwise honouring the setting just means clipping at 200%.
double scaled(BuildContext context, double px) =>
    MediaQuery.textScalerOf(context).scale(px);

/// The two-ended eyebrow row. Both ends are [Flexible] so a large text scale
/// wraps them instead of overflowing the screen.
class EyebrowRow extends StatelessWidget {
  const EyebrowRow(this.left, this.right, {super.key});

  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    // Wrap, not Row. A Row of Flexible+Expanded looks right until you read the
    // flex algorithm: free space is *allocated* before children are laid out,
    // so a loose Flexible that under-uses its share leaves the gap stranded
    // and the right-hand label lands mid-screen. Wrap with spaceBetween pins
    // both ends when they fit and drops the second onto its own line when they
    // do not — which is exactly what should happen at 200% text scale.
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.start,
        spacing: 16,
        runSpacing: 6,
        children: [Eyebrow(left), Eyebrow(right)],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small maths used across scenes.
// ---------------------------------------------------------------------------
double lerpD(double a, double b, double t) => a + (b - a) * t;

/// Frame-rate independent exponential approach.
double approach(double current, double target, double rate, double dt) =>
    current + (target - current) * (1 - math.exp(-rate * dt));

double smoothstep(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}
