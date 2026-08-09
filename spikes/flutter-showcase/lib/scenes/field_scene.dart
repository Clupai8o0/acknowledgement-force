import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../common.dart';
import '../data.dart';
import '../field.dart';
import '../shell.dart';
import '../theme.dart';

/// SCENE 5 — the field.
///
/// A GLSL fragment program running at surface resolution behind the whole app,
/// compiled by impellerc at build time and handed to Impeller as a Metal
/// shader. Two-octave value noise, two levels of domain warp, a breathing
/// focal lobe, a vignette and per-frame grain.
///
/// The grain is the part that actually matters and the part nobody asks for:
/// at these luminances (#141515 → #222324 is four percent) any smooth gradient
/// bands visibly on an OLED. A dither of ±0.016 kills it. That is a thing you
/// can only do per-pixel.
///
/// The second demonstration is the headline: the same program in ink mode is
/// used as the *fill* of the display serif via a ShaderMask, so the type is
/// made of the room it stands in — warping, grainy, and alive at 120 Hz.
///
/// Drag to move the light. Press and hold to make it swell.
class FieldScene extends StatefulWidget {
  const FieldScene({super.key, required this.cue, required this.field});

  final SceneCue cue;
  final FieldController field;

  @override
  State<FieldScene> createState() => _FieldSceneState();
}

class _FieldSceneState extends State<FieldScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  Timer? _auto;
  bool _held = false;
  Offset _focus = const Offset(0.5, 0.40);

  @override
  void initState() {
    super.initState();
    widget.cue.addListener(_onCue);
    if (widget.cue.active) _onCue();
  }

  void _onCue() {
    if (!mounted) return;
    if (widget.cue.active) {
      _push();
      _in
        ..reset()
        ..forward();
      if (kPose) {
        _focus = const Offset(0.34, 0.36);
        _held = true;
        _push();
      }
      if (kAutoDrive) {
        _auto?.cancel();
        var k = 0;
        _auto = Timer.periodic(const Duration(milliseconds: 700), (_) {
          if (!mounted || !widget.cue.active) return;
          k++;
          _focus = Offset(0.5 + 0.28 * ((k % 4) - 1.5) / 1.5, 0.28 + 0.22 * (k % 3));
          _held = k % 4 < 2;
          _push();
        });
      }
    } else {
      _auto?.cancel();
      _auto = null;
      _held = false;
      widget.field.targetBreath = 0;
    }
  }

  void _push() {
    widget.field
      ..targetIntensity = 1.0
      ..targetFocus = _focus
      ..targetBreath = _held ? 0.85 : 0.0;
  }

  void _moveTo(Offset local, Size size) {
    _focus = Offset(
      (local.dx / size.width).clamp(0.0, 1.0),
      (local.dy / size.height).clamp(0.0, 1.0),
    );
    _push();
  }

  @override
  void dispose() {
    _auto?.cancel();
    widget.cue.removeListener(_onCue);
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            _held = true;
            _moveTo(e.localPosition, size);
          },
          onPointerMove: (e) => _moveTo(e.localPosition, size),
          onPointerUp: (_) {
            _held = false;
            _push();
          },
          onPointerCancel: (_) {
            _held = false;
            _push();
          },
          child: ScenePad(
            child: AnimatedBuilder(
              animation: _in,
              builder: (context, _) {
                final t = Motion.ease.transform(_in.value);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: t,
                      child: const EyebrowRow('the field', 'glsl · impeller'),
                    ),
                    const Spacer(flex: 4),
                    _InkType(field: widget.field, t: t),
                    const SizedBox(height: 26),
                    Opacity(
                      opacity: (t * 1.4 - 0.4).clamp(0.0, 1.0),
                      child: Text(
                        'the background is not an image. it is a fragment '
                        'program: two octaves of value noise, two domain '
                        'warps, and a dither that stops the gradient banding '
                        'at four percent luminance.',
                        style: Face.meta,
                      ),
                    ),
                    const Spacer(flex: 5),
                    Opacity(opacity: t, child: _Readout(field: widget.field)),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// The claim, filled with the live field.
class _InkType extends StatelessWidget {
  const _InkType({required this.field, required this.t});

  final FieldController field;
  final double t;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: field,
      builder: (context, _) {
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < kClaim.length; i++)
              BlurText(
                kClaim[i],
                style: Face.claim.copyWith(color: Palette.ink),
                maxBlur: 12,
                rise: 18,
                t: ((t - i * 0.12) / 0.7).clamp(0.0, 1.0),
              ),
          ],
        );
        if (!field.ready) return text;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) =>
              field.inkShaderFor(bounds) ??
              ui.Gradient.linear(
                Offset.zero,
                const Offset(0, 1),
                const [Palette.ink, Palette.ink],
              ),
          child: text,
        );
      },
    );
  }
}

/// Live uniforms. A demo that shows numbers is a demo you can argue with.
class _Readout extends StatelessWidget {
  const _Readout({required this.field});

  final FieldController field;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: field,
      builder: (context, _) {
        final err = field.loadError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 60, child: DrawnRule(t: 1)),
            const SizedBox(height: 12),
            Text(
              err != null
                  ? 'shader failed to load — painted fallback active'
                  : 'uIntensity ${field.intensity.toStringAsFixed(2)}  ·  '
                      'uBreath ${field.breath.toStringAsFixed(2)}\n'
                      'uFocus ${field.focus.dx.toStringAsFixed(2)}, '
                      '${field.focus.dy.toStringAsFixed(2)}',
              style: Face.micro.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'drag to move the light · hold to make it swell',
              style: Face.micro.copyWith(color: Palette.inkContainer),
            ),
          ],
        );
      },
    );
  }
}
