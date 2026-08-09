import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'field.dart';
import 'scenes/claim_scene.dart';
import 'scenes/field_scene.dart';
import 'scenes/record_scene.dart';
import 'scenes/settle_scene.dart';
import 'scenes/sharpen_scene.dart';
import 'scenes/speak_scene.dart';
import 'theme.dart';

/// Auto-drive: `flutter run --dart-define=AUTODRIVE=1`.
/// Cycles scenes and exercises every animation without a hand on the glass, so
/// the memory sample can run for minutes. Each scene reads this and drives
/// itself; the shell only turns the pages.
const kAutoDrive = bool.fromEnvironment('AUTODRIVE');
const kAutoDriveDwell = Duration(seconds: 9);

/// Capture helpers, so the screenshots in shots/ are reproducible rather than
/// whatever the animation happened to be doing when I pressed the button.
/// `--dart-define=SCENE=n` opens on that scene; `--dart-define=POSE=1` puts
/// every scene into its most representative state a beat after it appears.
const kStartScene = int.fromEnvironment('SCENE');

/// `--dart-define=LOCK=true` keeps auto-drive on the starting scene instead of
/// turning pages, so one scene can be soaked in isolation.
const kLockScene = bool.fromEnvironment('LOCK');
const kPose = bool.fromEnvironment('POSE');

/// A scene's "you are on" signal. `generation` bumps every time the scene
/// becomes current, which is the cue to replay an entrance.
class SceneCue extends ChangeNotifier {
  bool _active = false;
  int _generation = 0;

  bool get active => _active;
  int get generation => _generation;

  void setActive(bool v) {
    if (v == _active) return;
    _active = v;
    if (v) _generation++;
    notifyListeners();
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final _field = FieldController();
  final _pc = PageController(initialPage: kStartScene);
  final _page = ValueNotifier<double>(kStartScene.toDouble());
  final _index = ValueNotifier<int>(kStartScene);
  final _hintGone = ValueNotifier<bool>(false);

  late final List<SceneCue> _cues;
  late final List<Widget> _scenes;
  late final List<String> _names;

  Timer? _auto;

  @override
  void initState() {
    super.initState();
    _field.load();

    _names = const [
      'the claim',
      'the record',
      'hold to speak',
      'the settle',
      'the field',
      'the sharpening',
    ];
    _cues = List.generate(_names.length, (_) => SceneCue());
    _scenes = [
      ClaimScene(cue: _cues[0], field: _field),
      RecordScene(cue: _cues[1], field: _field),
      SpeakScene(cue: _cues[2], field: _field),
      SettleScene(cue: _cues[3], field: _field),
      FieldScene(cue: _cues[4], field: _field),
      SharpenScene(cue: _cues[5], field: _field),
    ];

    _pc.addListener(() {
      final p = _pc.page;
      if (p == null) return;
      _page.value = p;
      if (p != 0 && !_hintGone.value) _hintGone.value = true;
      final i = p.round();
      if (i != _index.value) {
        _index.value = i;
        for (var k = 0; k < _cues.length; k++) {
          _cues[k].setActive(k == i);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cues[kStartScene].setActive(true);
      if (kAutoDrive && !kLockScene) _startAutoDrive();
    });
  }

  void _startAutoDrive() {
    _auto = Timer.periodic(kAutoDriveDwell, (_) {
      if (!mounted) return;
      final next = (_index.value + 1) % _scenes.length;
      _pc.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Motion.easeSoft,
      );
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _pc.dispose();
    _page.dispose();
    _index.dispose();
    _hintGone.dispose();
    for (final c in _cues) {
      c.dispose();
    }
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Palette.base,
      child: Stack(
        children: [
          Positioned.fill(child: BreathingField(controller: _field)),
          Positioned.fill(
            child: PageView.builder(
              controller: _pc,
              itemCount: _scenes.length,
              physics: const _ForcePageScroll(),
              itemBuilder: (context, i) {
                final scene = _scenes[i];
                // TickerMode gates every AnimationController and Ticker below
                // it. Offscreen scenes stop animating entirely — that is what
                // keeps six live animated scenes at one scene's frame cost.
                return ValueListenableBuilder<double>(
                  valueListenable: _page,
                  child: scene,
                  builder: (_, p, child) => TickerMode(
                    enabled: (p - i).abs() < 0.999,
                    child: child!,
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _Indicator(
              page: _page,
              index: _index,
              names: _names,
              hintGone: _hintGone,
              onJump: (i) => _pc.animateToPage(
                i,
                duration: const Duration(milliseconds: 460),
                curve: Motion.easeSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// iOS page physics, slightly heavier. The default is a touch eager for
/// something this quiet.
class _ForcePageScroll extends PageScrollPhysics {
  const _ForcePageScroll({super.parent});

  @override
  _ForcePageScroll applyTo(ScrollPhysics? ancestor) =>
      _ForcePageScroll(parent: buildParent(ancestor));

  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 0.55, stiffness: 105, damping: 21);
}

// ---------------------------------------------------------------------------
// The indicator. Six hairlines and the scene's name. It has to say "there is
// more here" without ever competing with the type — so it is 10 px tall, sits
// in the bottom margin, and the only thing that moves is a 20 px bar sliding
// on a spring.
// ---------------------------------------------------------------------------
class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.page,
    required this.index,
    required this.names,
    required this.hintGone,
    required this.onJump,
  });

  final ValueListenable<double> page;
  final ValueListenable<int> index;
  final List<String> names;
  final ValueListenable<bool> hintGone;
  final void Function(int) onJump;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom + 14, left: 24, right: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 30,
            child: ValueListenableBuilder<double>(
              valueListenable: page,
              builder: (_, p, _) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < names.length; i++)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onJump(i),
                      child: SizedBox(
                        width: 44,
                        height: 30,
                        child: Center(
                          child: _Tick(d: (p - i).abs().clamp(0.0, 1.0)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 24,
            child: ValueListenableBuilder<int>(
              valueListenable: index,
              builder: (_, i, _) => ValueListenableBuilder<bool>(
                valueListenable: hintGone,
                builder: (_, gone, _) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Motion.ease,
                  switchOutCurve: Motion.easeIn,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: child,
                  ),
                  child: Text(
                    gone
                        ? names[i].toUpperCase()
                        : '${names[i].toUpperCase()}   ·   SWIPE',
                    key: ValueKey('$i$gone'),
                    style: Face.label,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tick extends StatelessWidget {
  const _Tick({required this.d});

  /// Distance from the current page, 0 = this one.
  final double d;

  @override
  Widget build(BuildContext context) {
    final on = 1 - d;
    return Container(
      width: 12 + 8 * on,
      height: 1.5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        color: Color.lerp(Palette.outlineSoft, Palette.mute, on),
      ),
    );
  }
}
