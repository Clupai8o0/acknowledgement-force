import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../common.dart';
import '../data.dart';
import '../field.dart';
import '../shell.dart';
import '../theme.dart';

/// SCENE 4 — the settle.
///
/// The day's verdict is a physical object you put somewhere. You can tap a
/// verdict, or you can pick the mark up and throw it — and the throw's velocity
/// is handed straight to the spring, so a hard fling overshoots and a gentle
/// one does not.
///
/// The point of the scene is interruption. Change your mind mid-flight and the
/// mark does not restart, it *redirects*: [Spring1D.retarget] rebuilds the
/// simulation seeded with the mark's current position and current velocity.
/// Nothing here uses a Curve. There is a 620 ms window before the verdict
/// commits, which is exactly the window in which interrupting has to feel
/// right.
///
/// Motion class demonstrated: velocity-carrying, retargetable 2-D springs.
class SettleScene extends StatefulWidget {
  const SettleScene({super.key, required this.cue, required this.field});

  final SceneCue cue;
  final FieldController field;

  @override
  State<SettleScene> createState() => _SettleSceneState();
}

class _SettleSceneState extends State<SettleScene>
    with SingleTickerProviderStateMixin {
  late final _m = _SettleModel();
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  Timer? _commit;
  Timer? _auto;
  int _autoStep = 0;

  @override
  void initState() {
    super.initState();
    widget.cue.addListener(_onCue);
    _m.onCommitted = () {
      if (mounted) setState(() {});
    };
    _ticker.start();
    if (widget.cue.active) _onCue();
  }

  void _tick(Duration now) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : (now - _last).inMicroseconds / 1e6;
    _last = now;
    _m.advance(dt.clamp(0.0, 1 / 20));
  }

  void _onCue() {
    if (!mounted) return;
    if (widget.cue.active) {
      widget.field
        ..targetIntensity = 0.55
        ..targetFocus = const Offset(0.5, 0.62)
        ..targetBreath = 0;
      _reset();
      if (kPose) {
        Timer(const Duration(milliseconds: 900), () {
          if (mounted && widget.cue.active) _m.aim(Mark.kept);
        });
      }
      if (kAutoDrive) {
        _auto?.cancel();
        _autoStep = 0;
        // Deliberately retargets mid-flight every other beat: choose KEPT,
        // then 260 ms later change to BROKEN before the commit window closes.
        _auto = Timer.periodic(const Duration(milliseconds: 1100), (_) {
          if (!mounted || !widget.cue.active) return;
          switch (_autoStep++ % 6) {
            case 0:
              _choose(Mark.kept);
            case 1:
              Timer(const Duration(milliseconds: 240),
                  () => mounted ? _choose(Mark.broken) : null);
            case 3:
              _reset();
            case 4:
              _choose(Mark.unsettled);
            case 5:
              _reset();
          }
        });
      }
    } else {
      _auto?.cancel();
      _auto = null;
      _commit?.cancel();
    }
  }

  void _reset() {
    _commit?.cancel();
    _m.reset();
    if (mounted) setState(() {});
  }

  void _choose(Mark mark, {Offset? velocity}) {
    if (_m.committed) return;
    _m.aim(mark, velocity: velocity);
    _commit?.cancel();
    // The window in which changing your mind is free.
    _commit = Timer(const Duration(milliseconds: 620), () {
      if (!mounted || _m.aimed != mark) return;
      _m.commit();
    });
  }

  void _release(Offset velocity) {
    final target = _m.nearestZone(velocity);
    _commit?.cancel();
    if (target == null) {
      _m.aim(null, velocity: velocity);
      return;
    }
    _choose(target, velocity: velocity);
  }

  @override
  void dispose() {
    _auto?.cancel();
    _commit?.cancel();
    widget.cue.removeListener(_onCue);
    _ticker.dispose();
    _m.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScenePad(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Eyebrow('the settle'),
              Pressable(
                onTap: _reset,
                child: const SizedBox(
                  height: Metrics.tap,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Eyebrow('reset'),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                _m.layout(Size(box.maxWidth, box.maxHeight));
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      top: _m.copyY,
                      width: box.maxWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(kClaim.join(' '), style: Face.claimSmall),
                          const SizedBox(height: 14),
                          Text(
                            _m.committed
                                ? 'the day is on the record. goodnight.'
                                : 'throw it, or tap. you have a moment to '
                                    'change your mind.',
                            style: Face.meta,
                          ),
                        ],
                      ),
                    ),
                    _zoneChrome(Mark.kept, 'KEPT'),
                    _zoneChrome(Mark.broken, 'BROKEN'),
                    _escape(),
                    // Painted last: the token has to fly *over* the pills, not
                    // under them. CustomPaint with no child does not absorb
                    // hits, so the zones underneath stay tappable.
                    Positioned.fill(
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _SettlePainter(_m),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ),
                    // The token's own hit area follows it, so you can pick the
                    // mark up mid-flight.
                    AnimatedBuilder(
                      animation: _m,
                      builder: (context, _) {
                        final p = _m.pos;
                        return Positioned(
                          left: p.dx - 34,
                          top: p.dy - 34,
                          width: 68,
                          height: 68,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (_) {
                              _commit?.cancel();
                              _m.beginDrag();
                            },
                            onPanUpdate: (d) => _m.dragBy(d.delta),
                            onPanEnd: (d) {
                              _m.endDrag();
                              _release(d.velocity.pixelsPerSecond);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoneChrome(Mark mark, String label) {
    final r = _m.zoneRect(mark);
    return Positioned.fromRect(
      rect: r,
      child: AnimatedBuilder(
        animation: _m,
        builder: (context, _) {
          final hot = _m.hotness(mark);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _choose(mark),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color.lerp(
                  Palette.containerLow.withValues(alpha: 0.55),
                  Palette.container,
                  hot,
                ),
                borderRadius: BorderRadius.circular(r.height / 2),
                border: Border.all(
                  color: Color.lerp(Palette.outlineSoft, Palette.bright, hot)!,
                  width: 1,
                ),
              ),
              // The label steps aside for the mark. Once the token is actually
              // aimed here, the word has done its job and the object takes the
              // space — otherwise the mark lands on top of its own caption.
              child: Opacity(
                opacity: 1 - smoothstep(0.74, 0.99, hot),
                child: Text(
                  label,
                  style: Face.button.copyWith(
                    color: Color.lerp(Palette.inkContainer, Palette.ink, hot),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _escape() {
    final r = _m.zoneRect(Mark.unsettled);
    return Positioned.fromRect(
      rect: r,
      child: AnimatedBuilder(
        animation: _m,
        builder: (context, _) {
          final hot = _m.hotness(Mark.unsettled);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            // D7: one tap, no confirm, no guilt copy.
            onTap: () => _choose(Mark.unsettled),
            child: Center(
              child: Text(
                'Not tonight',
                style: Face.meta.copyWith(
                  color: Color.lerp(Palette.mute, Palette.ash, hot),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _SettleModel extends ChangeNotifier {
  static const _fly =
      SpringDescription(mass: 1, stiffness: 205, damping: 21); // ~4% overshoot
  static const _snap =
      SpringDescription(mass: 1, stiffness: 320, damping: 30);

  final x = Spring1D(value: 0, spring: _fly);
  final y = Spring1D(value: 0, spring: _fly);
  final scale = Spring1D(value: 1, spring: _snap);

  VoidCallback? onCommitted;

  static const _stripY = 28.0;

  Size _size = Size.zero;
  Offset _home = Offset.zero;
  Offset _slot = Offset.zero;
  double copyY = 0;

  final _zones = <Mark, Rect>{};
  final _hot = <Mark, double>{
    Mark.kept: 0,
    Mark.broken: 0,
    Mark.unsettled: 0,
  };

  Mark? aimed;
  bool committed = false;
  bool _dragging = false;
  Offset _drag = Offset.zero;

  /// Trail. 18 samples, ring buffer, no allocation.
  static const trail = 18;
  final tx = Float32List(trail);
  final ty = Float32List(trail);
  int th = 0;
  double _trailAcc = 0;

  Offset get pos => _dragging ? _drag : Offset(x.value, y.value);
  double get speed =>
      _dragging ? 0 : math.sqrt(x.velocity * x.velocity + y.velocity * y.velocity);
  bool get dragging => _dragging;
  Offset get slot => _slot;
  double hotness(Mark m) => _hot[m] ?? 0;
  Rect zoneRect(Mark m) => _zones[m] ?? Rect.zero;

  void layout(Size s) {
    if (s == _size) return;
    _size = s;
    final w = s.width, h = s.height;
    _slot = Offset(w - Metrics.markSize / 2 - 1, _stripY);
    copyY = h * 0.15;
    _home = Offset(w / 2, h * 0.48);

    const pillH = 52.0;
    final pillW = math.min(148.0, (w - 16) / 2);
    final pillY = h * 0.70;
    _zones[Mark.kept] = Rect.fromLTWH(
        w / 2 - pillW - 8, pillY, pillW, pillH);
    _zones[Mark.broken] = Rect.fromLTWH(w / 2 + 8, pillY, pillW, pillH);
    _zones[Mark.unsettled] =
        Rect.fromLTWH(w / 2 - 80, pillY + pillH + 26, 160, 40);

    x.reset(_home.dx);
    y.reset(_home.dy);
    for (var i = 0; i < trail; i++) {
      tx[i] = _home.dx;
      ty[i] = _home.dy;
    }
  }

  void reset() {
    committed = false;
    aimed = null;
    _dragging = false;
    x.reset(_home.dx);
    y.reset(_home.dy);
    scale.reset(1);
    for (var i = 0; i < trail; i++) {
      tx[i] = _home.dx;
      ty[i] = _home.dy;
    }
    notifyListeners();
  }

  void beginDrag() {
    if (committed) return;
    _dragging = true;
    _drag = Offset(x.value, y.value);
    aimed = null;
  }

  void dragBy(Offset d) {
    if (!_dragging) return;
    _drag += d;
  }

  void endDrag() {
    if (!_dragging) return;
    _dragging = false;
    x.reset(_drag.dx);
    y.reset(_drag.dy);
  }

  /// Predicts where a fling would land and picks the zone under it. 0.11 s of
  /// lookahead is roughly how far ahead of the finger the eye already is.
  Mark? nearestZone(Offset velocity) {
    final landing = _drag + velocity * 0.11;
    Mark? best;
    var bestD = double.infinity;
    for (final e in _zones.entries) {
      final d = (e.value.center - landing).distance;
      final reach = e.value.longestSide * 0.85 + 40;
      if (d < reach && d < bestD) {
        bestD = d;
        best = e.key;
      }
    }
    return best;
  }

  /// Retarget. Velocity carries — this is the whole scene.
  void aim(Mark? mark, {Offset? velocity}) {
    if (committed) return;
    aimed = mark;
    final target = mark == null ? _home : _zones[mark]!.center;
    x.retarget(target.dx, velocity: velocity?.dx);
    y.retarget(target.dy, velocity: velocity?.dy);
    scale.retarget(mark == null ? 1 : 1.06);
    notifyListeners();
  }

  void commit() {
    if (committed || aimed == null) return;
    committed = true;
    x.retarget(_slot.dx);
    y.retarget(_slot.dy);
    scale.retarget(0.30);
    onCommitted?.call();
    notifyListeners();
  }

  void advance(double dt) {
    if (!_dragging) {
      x.advance(dt);
      y.advance(dt);
    }
    scale.advance(dt);

    // Zone hotness: proximity of the token, eased. Gives the pills a sense of
    // magnetism without a single hard hit-test boundary.
    for (final e in _zones.entries) {
      final target = committed
          ? 0.0
          : (aimed == e.key
              ? 1.0
              : (1 - ((pos - e.value.center).distance / 130)).clamp(0.0, 1.0) *
                  0.7);
      _hot[e.key] = approach(_hot[e.key]!, target, 9, dt);
    }

    // Trail samples on its own clock, so the streak length reads the same at
    // 60 and 120 Hz.
    _trailAcc += dt;
    while (_trailAcc >= 1 / 90) {
      _trailAcc -= 1 / 90;
      th = (th + 1) % trail;
      tx[th] = pos.dx;
      ty[th] = pos.dy;
    }
    notifyListeners();
  }
}

class _SettlePainter extends CustomPainter {
  _SettlePainter(this.m) : super(repaint: m);

  final _SettleModel m;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;

    // The strip, with today's slot waiting at the right.
    const gap = 15.0;
    final n = kRecord.length;
    for (var i = 0; i < n; i++) {
      final cx = size.width - (n - i) * gap - 1;
      const cy = _SettleModel._stripY;
      final mark = kRecord[i].mark;
      p
        ..style = PaintingStyle.fill
        ..color = mark == Mark.kept ? Palette.ink : Palette.stone;
      if (mark == Mark.unsettled) {
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Palette.mute;
        canvas.drawCircle(Offset(cx, cy), 3.4, p);
      } else {
        canvas.drawCircle(Offset(cx, cy), 3.9, p);
      }
    }
    // Today's empty slot.
    if (!m.committed || !m.scale.settled) {
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Palette.mute.withValues(alpha: m.committed ? 0.35 : 1.0);
      canvas.drawCircle(m.slot, 4.6, p);
    }

    // Trail — only when it is actually moving, otherwise it reads as a smear.
    final sp = m.speed;
    final trailAmt = (sp / 900).clamp(0.0, 1.0);
    if (trailAmt > 0.02 && !m.committed) {
      p.style = PaintingStyle.fill;
      for (var k = 1; k < _SettleModel.trail; k++) {
        final i = (m.th - k + _SettleModel.trail) % _SettleModel.trail;
        final f = 1 - k / _SettleModel.trail;
        p.color = _colorFor(m.aimed).withValues(
          alpha: (0.16 * f * f * trailAmt).clamp(0.0, 1.0),
        );
        canvas.drawCircle(
          Offset(m.tx[i], m.ty[i]),
          _radius(m) * f * 0.85,
          p,
        );
      }
    }

    // The token.
    final r = _radius(m);
    final pos = m.pos;
    final color = _colorFor(m.aimed);
    if (m.aimed == Mark.unsettled) {
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = Palette.mute;
      canvas.drawCircle(pos, r - 0.9, p);
    } else {
      // A soft aura so the token has presence at rest without a drop shadow,
      // which at these luminances would just look like dirt.
      p
        ..style = PaintingStyle.fill
        ..shader = null
        ..color = color.withValues(alpha: 0.055);
      canvas.drawCircle(pos, r * 3.1, p);
      p.color = color.withValues(alpha: 0.10);
      canvas.drawCircle(pos, r * 1.9, p);
      p.color = color;
      canvas.drawCircle(pos, r, p);
    }

    // Ring showing the commit window closing.
    if (m.aimed != null && !m.committed) {
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Palette.bright.withValues(alpha: 0.5);
      canvas.drawCircle(pos, r + 11, p);
    }
  }

  double _radius(_SettleModel m) => 11.0 * m.scale.value.clamp(0.15, 1.4);

  Color _colorFor(Mark? m) => switch (m) {
    Mark.kept => Palette.ink,
    Mark.broken => Palette.stone,
    Mark.unsettled => Palette.mute,
    null => Palette.inkContainer,
  };

  @override
  bool shouldRepaint(_SettlePainter old) => false;
}
