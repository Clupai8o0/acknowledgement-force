import 'dart:async';

import 'package:flutter/widgets.dart';

import '../common.dart';
import '../data.dart';
import '../field.dart';
import '../shell.dart';
import '../theme.dart';

/// SCENE 6 — the sharpening. (My pick.)
///
/// D4: "rewording until it's true *is* the work; you'll rewrite a claim five
/// times before it fits." D9 puts the first forced rewrite on day seven. That
/// is the one moment in Force where a sentence *changes*, and every other app
/// would render it as a crossfade between two blocks of text.
///
/// Instead this diffs the two sentences at word level (LCS over lowercased
/// tokens), then animates the three classes separately:
///   · words that survive TRANSLATE to their new position and never fade
///   · words that die blur out and drift up
///   · words that arrive blur in from below, staggered
///
/// The effect is that the sentence visibly *rewrites itself* — "I" holds its
/// place while everything around it is replaced. It is the most convincing
/// argument I have that Flutter's text stack is a real one: I get per-word
/// metrics out of TextPainter and can lay them out myself.
///
/// Motion class demonstrated: layout-aware text choreography / a keyed diff
/// driving three simultaneous transition classes.
class SharpenScene extends StatefulWidget {
  const SharpenScene({super.key, required this.cue, required this.field});

  final SceneCue cue;
  final FieldController field;

  @override
  State<SharpenScene> createState() => _SharpenSceneState();
}

class _SharpenSceneState extends State<SharpenScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
  );

  int _index = 0;
  int _prev = 0;
  double _width = 0;
  List<_Item> _items = const [];
  Timer? _auto;

  static final _style = Face.claim.copyWith(fontSize: 29, height: 1.36);

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
        ..targetIntensity = 0.58
        ..targetFocus = const Offset(0.42, 0.40)
        ..targetBreath = 0;
      setState(() {
        _prev = _index = 0;
        _items = const [];
      });
      _c.value = 1;
      if (kPose) {
        void poseStep() {
          if (mounted && widget.cue.active) _advance();
        }
        Timer(const Duration(milliseconds: 500), poseStep);
        Timer(const Duration(milliseconds: 1700), poseStep);
      }
      if (kAutoDrive) {
        _auto?.cancel();
        _auto = Timer.periodic(const Duration(milliseconds: 2400), (_) {
          if (mounted && widget.cue.active) _advance();
        });
      }
    } else {
      _auto?.cancel();
      _auto = null;
    }
  }

  void _advance() {
    setState(() {
      _prev = _index;
      _index = (_index + 1) % kDrafts.length;
      _items = _diff(_prev, _index, _width);
    });
    _c
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _auto?.cancel();
    widget.cue.removeListener(_onCue);
    _c.dispose();
    super.dispose();
  }

  // --- measurement --------------------------------------------------------
  // Measured once per (draft, width) and memoised. TextPainter.layout on a
  // single word is fast, but "fast" times eleven words times 120 Hz is not,
  // and there is no reason to pay it more than once.
  static final _cache = <String, List<_Word>>{};

  List<_Word> _measure(int draftIndex, double maxWidth) {
    final key = '$draftIndex@${maxWidth.round()}';
    final hit = _cache[key];
    if (hit != null) return hit;

    final draft = kDrafts[draftIndex];
    final tp = TextPainter(textDirection: TextDirection.ltr);
    double widthOf(String s) {
      tp
        ..text = TextSpan(text: s, style: _style)
        ..layout();
      return tp.width;
    }

    final space = widthOf(' '); // NBSP measures a real space reliably
    final lineHeight = _style.fontSize! * _style.height!;
    final out = <_Word>[];
    for (var li = 0; li < draft.lines.length; li++) {
      var x = 0.0;
      for (final w in draft.lines[li].split(' ')) {
        final ww = widthOf(w);
        out.add(_Word(w, Offset(x, li * lineHeight), ww));
        x += ww + space;
      }
    }
    tp.dispose();
    _cache[key] = out;
    return out;
  }

  /// LCS over lowercased, punctuation-stripped tokens. Eleven words maximum,
  /// so the quadratic table is 121 ints and nobody cares.
  List<_Item> _diff(int fromI, int toI, double width) {
    final a = _measure(fromI, width);
    final b = _measure(toI, width);
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r"[^a-z']"), '');

    final n = a.length, m = b.length;
    final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    for (var i = n - 1; i >= 0; i--) {
      for (var j = m - 1; j >= 0; j--) {
        dp[i][j] = norm(a[i].text) == norm(b[j].text)
            ? dp[i + 1][j + 1] + 1
            : (dp[i + 1][j] > dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1]);
      }
    }

    final items = <_Item>[];
    var i = 0, j = 0, order = 0;
    while (i < n && j < m) {
      if (norm(a[i].text) == norm(b[j].text)) {
        items.add(_Item(b[j].text, from: a[i].pos, to: b[j].pos, order: j));
        i++;
        j++;
      } else if (dp[i + 1][j] >= dp[i][j + 1]) {
        items.add(_Item(a[i].text, from: a[i].pos, to: null, order: order++));
        i++;
      } else {
        items.add(_Item(b[j].text, from: null, to: b[j].pos, order: j));
        j++;
      }
    }
    while (i < n) {
      items.add(_Item(a[i].text, from: a[i].pos, to: null, order: order++));
      i++;
    }
    while (j < m) {
      items.add(_Item(b[j].text, from: null, to: b[j].pos, order: j));
      j++;
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final draft = kDrafts[_index];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _advance,
      child: ScenePad(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EyebrowRow('day 7 · sharpen', 'draft ${_index + 1} of ${kDrafts.length}'),
            const Spacer(flex: 4),
            LayoutBuilder(
              builder: (context, box) {
                if (_width != box.maxWidth) {
                  _width = box.maxWidth;
                  if (_items.isEmpty) {
                    _items = _diff(_prev, _index, _width);
                  }
                }
                final words = _measure(_index, _width);
                final lines = kDrafts[_index].lines.length;
                final h = lines * _style.fontSize! * _style.height!;
                return SizedBox(
                  width: box.maxWidth,
                  height: h + 6,
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final it in _items) _word(it, words.length),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 34),
            _verdict(draft),
            const Spacer(flex: 5),
            Text('tap to rewrite', style: Face.micro),
          ],
        ),
      ),
    );
  }

  Widget _word(_Item it, int total) {
    final t = _c.value;
    if (it.to == null) {
      // Dying: out fast, up, and blurring — the sentence is being taken away
      // from you, so it must not linger.
      final k = Motion.easeIn.transform((t / 0.42).clamp(0.0, 1.0));
      if (k >= 1) return const SizedBox.shrink();
      return Positioned(
        left: it.from!.dx,
        top: it.from!.dy - 12 * k,
        child: BlurText(
          it.text,
          style: _style,
          t: 1 - k,
          rise: 0,
          maxBlur: 9,
        ),
      );
    }
    if (it.from == null) {
      // Arriving: staggered, from below, out of blur.
      final start = 0.30 + 0.045 * it.order;
      final k = ((t - start) / (1 - start)).clamp(0.0, 1.0);
      return Positioned(
        left: it.to!.dx,
        top: it.to!.dy,
        child: BlurText(
          it.text,
          style: _style,
          t: Motion.ease.transform(k),
          rise: 14,
          maxBlur: 10,
        ),
      );
    }
    // Surviving: it moves. It never fades, because it never left.
    final k = Motion.ease.transform(((t - 0.10) / 0.80).clamp(0.0, 1.0));
    final p = Offset.lerp(it.from!, it.to!, k)!;
    return Positioned(
      left: p.dx,
      top: p.dy,
      child: Text(it.text, style: _style),
    );
  }

  Widget _verdict(ClaimDraft d) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 340),
      switchInCurve: Motion.ease,
      switchOutCurve: Motion.easeIn,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - a.value)),
          child: child,
        ),
      ),
      child: Column(
        key: ValueKey(d.verdict),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: d.good ? Palette.ink : Palette.mute,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                d.verdict,
                style: Face.label.copyWith(
                  color: d.good ? Palette.ash : Palette.mute,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(d.reason, style: Face.meta),
        ],
      ),
    );
  }
}

class _Word {
  const _Word(this.text, this.pos, this.width);
  final String text;
  final Offset pos;
  final double width;
}

class _Item {
  const _Item(this.text, {this.from, this.to, required this.order});
  final String text;
  final Offset? from;
  final Offset? to;
  final int order;
}
