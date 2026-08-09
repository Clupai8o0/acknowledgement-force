import 'dart:async';

import 'package:flutter/widgets.dart';

import '../common.dart';
import '../data.dart';
import '../field.dart';
import '../shell.dart';
import '../theme.dart';

/// SCENE 1 — the claim entrance.
///
/// The emotional centre of the product. The claim is not "content that loads",
/// it is a sentence being said to you, so it arrives the way a sentence is
/// spoken: word by word, out of blur, from slightly below, decelerating hard.
/// The attribution follows a beat later because the evidence should feel like
/// it is being *offered*, not stated at the same time as the assertion.
///
/// Motion class demonstrated: staggered per-word entrance with animated blur,
/// translate and opacity, all off one controller and zero saveLayers.
class ClaimScene extends StatefulWidget {
  const ClaimScene({super.key, required this.cue, required this.field});

  final SceneCue cue;
  final FieldController field;

  @override
  State<ClaimScene> createState() => _ClaimSceneState();
}

class _ClaimSceneState extends State<ClaimScene>
    with SingleTickerProviderStateMixin {
  // Absolute score, in ms. Writing the timing as a score rather than as a pile
  // of Intervals is the only way I could keep eleven staggered words legible.
  static const _totalMs = 3000;
  static const _total = _totalMs * 1.0;
  static const _wordStep = 78.0;
  static const _wordDur = 1050.0;
  static const _wordsAt = 150.0;
  static const _ruleAt = 1450.0, _ruleDur = 900.0;
  static const _attrAt = 1750.0, _attrDur = 900.0;
  static const _footAt = 2400.0, _footDur = 600.0;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _totalMs),
  );

  late final List<List<String>> _words =
      kClaim.map((l) => l.split(' ')).toList(growable: false);
  Timer? _loop;

  @override
  void initState() {
    super.initState();
    widget.cue.addListener(_onCue);
    if (widget.cue.active) _onCue();
  }

  void _onCue() {
    if (!mounted) return;
    if (widget.cue.active) {
      widget.field
        ..targetIntensity = 0.62
        ..targetFocus = const Offset(0.46, 0.44)
        ..targetBreath = 0;
      _replay();
      if (kAutoDrive) {
        _loop?.cancel();
        _loop = Timer.periodic(const Duration(milliseconds: 4200), (_) {
          if (mounted && widget.cue.active) _replay();
        });
      }
    } else {
      _loop?.cancel();
      _loop = null;
    }
  }

  void _replay() {
    _c
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _loop?.cancel();
    widget.cue.removeListener(_onCue);
    _c.dispose();
    super.dispose();
  }

  double _win(double ms, double at, double dur, {Curve c = Motion.ease}) =>
      c.transform(((ms - at) / dur).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _replay,
      child: ScenePad(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final ms = _c.value * _total;
            final head = _win(ms, 0, 700);
            final rule = _win(ms, _ruleAt, _ruleDur, c: Motion.easeSoft);
            final attr = _win(ms, _attrAt, _attrDur);
            final foot = _win(ms, _footAt, _footDur);

            var wi = 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: head,
                  child: const EyebrowRow('night 19 of 28', 'tue 4 aug'),
                ),
                const Spacer(flex: 6),
                // A word-by-word Row cannot wrap, so at 200% text scale it
                // would overflow. FittedBox keeps the whole line on screen and
                // the per-word choreography intact.
                for (final line in _words)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var j = 0; j < line.length; j++)
                          BlurText(
                            j == line.length - 1 ? line[j] : '${line[j]} ',
                            style: Face.claim,
                            maxBlur: 11,
                            rise: 17,
                            t: _win(
                              ms,
                              _wordsAt + (wi++) * _wordStep,
                              _wordDur,
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 78,
                  child: DrawnRule(t: rule, color: Palette.outline),
                ),
                const SizedBox(height: 22),
                Opacity(
                  opacity: attr,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - attr)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kAttributionLead, style: Face.micro),
                        const SizedBox(height: 5),
                        // The quote is the mechanic, not decoration (D9): it is
                        // the proof the sentence came out of your mouth.
                        BlurText(
                          kAttribution,
                          style: Face.body.copyWith(color: Palette.ash),
                          maxBlur: 6,
                          rise: 8,
                          t: attr,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 5),
                Opacity(
                  opacity: foot,
                  child: Text('tap to replay', style: Face.micro),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
