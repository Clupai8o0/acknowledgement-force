import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// The breathing field.
///
/// One fragment shader, one ticker, painted once behind the whole app. Every
/// scene writes its wishes into [FieldController]; the controller eases toward
/// them so the background never cuts. There is deliberately no second shader
/// instance anywhere in this app — a full-screen fragment program is the one
/// thing here with a real per-pixel cost, and it should be paid exactly once.
class FieldController extends ChangeNotifier {
  FieldController();

  ui.FragmentShader? _shader;

  /// A second instance for the ink-mode fill. One [ui.FragmentShader] must not
  /// be used twice in a frame with different uniforms — the object is mutable
  /// and the recorded picture only holds a reference, so the second setFloat
  /// would retroactively change the first draw. Two instances off one program
  /// is the fix, and it costs nothing.
  ui.FragmentShader? _inkShader;
  String? loadError;

  bool get ready => _shader != null;

  double time = 0;

  // Eased state. `_t*` is the target a scene asked for.
  double _intensity = 0.55, _tIntensity = 0.55;
  double _breath = 0, _tBreath = 0;
  Offset _focus = const Offset(0.5, 0.42), _tFocus = const Offset(0.5, 0.42);

  double get intensity => _intensity;
  double get breath => _breath;
  Offset get focus => _focus;

  set targetIntensity(double v) => _tIntensity = v;
  set targetBreath(double v) => _tBreath = v;
  set targetFocus(Offset v) => _tFocus = v;

  Future<void> load() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/field.frag');
      _shader = program.fragmentShader();
      _inkShader = program.fragmentShader();
    } catch (e) {
      loadError = '$e';
      debugPrint('[field] shader load failed: $e — falling back to a painted gradient');
    }
    notifyListeners();
  }

  /// Advance. `dt` is real seconds; the easing is frame-rate independent so the
  /// field looks the same at 60 and 120 Hz.
  void tick(double dt) {
    time += dt;
    final k = 1 - math.exp(-dt * 3.2);
    _intensity += (_tIntensity - _intensity) * k;
    _breath += (_tBreath - _breath) * (1 - math.exp(-dt * 6.0));
    _focus = Offset(
      _focus.dx + (_tFocus.dx - _focus.dx) * k,
      _focus.dy + (_tFocus.dy - _focus.dy) * k,
    );
    notifyListeners();
  }

  ui.FragmentShader? shaderFor(Size size) {
    final s = _shader;
    if (s == null) return null;
    s
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time)
      ..setFloat(3, _intensity)
      ..setFloat(4, _breath)
      ..setFloat(5, _focus.dx)
      ..setFloat(6, _focus.dy)
      ..setFloat(7, 0);
    return s;
  }

  /// The ink-range variant, for filling type with the field.
  ui.FragmentShader? inkShaderFor(Rect bounds) {
    final s = _inkShader;
    if (s == null) return null;
    s
      ..setFloat(0, bounds.width)
      ..setFloat(1, bounds.height)
      ..setFloat(2, time)
      ..setFloat(3, 1)
      ..setFloat(4, _breath)
      ..setFloat(5, 0.5)
      ..setFloat(6, 0.5)
      ..setFloat(7, 1);
    return s;
  }

  @override
  void dispose() {
    _shader?.dispose();
    _inkShader?.dispose();
    _shader = null;
    _inkShader = null;
    super.dispose();
  }
}

/// The widget. A [RepaintBoundary] wrapping a single [CustomPaint] whose
/// painter repaints off the controller — the widget tree above it never
/// rebuilds, so the field costs one raster pass and zero framework work.
class BreathingField extends StatefulWidget {
  const BreathingField({super.key, required this.controller});

  final FieldController controller;

  @override
  State<BreathingField> createState() => _BreathingFieldState();
}

class _BreathingFieldState extends State<BreathingField>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration now) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : (now - _last).inMicroseconds / 1e6;
    _last = now;
    // Guard against a hitch producing a huge dt (e.g. resuming from background).
    widget.controller.tick(dt.clamp(0.0, 1 / 20));
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _FieldPainter(widget.controller),
        size: Size.infinite,
        isComplex: true,
        willChange: true,
      ),
    );
  }
}

class _FieldPainter extends CustomPainter {
  _FieldPainter(this.c) : super(repaint: c);

  final FieldController c;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = c.shaderFor(size);
    if (shader == null) {
      // Fallback: the field's silhouette in plain Dart, so a shader-compile
      // failure degrades to "slightly duller" rather than "black rectangle".
      final r = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawRect(r, Paint()..color = Palette.base);
      canvas.drawRect(
        r,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(size.width * c.focus.dx, size.height * c.focus.dy),
            size.width * 0.95,
            [
              Palette.containerLow.withValues(alpha: 0.9 * c.intensity),
              Palette.base.withValues(alpha: 0.0),
            ],
          ),
      );
      return;
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_FieldPainter old) => false;
}
