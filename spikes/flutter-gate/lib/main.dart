import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'gate_view.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _Instrument.arm();
  runApp(const GateApp());
}

class GateApp extends StatelessWidget {
  const GateApp({super.key});

  @override
  Widget build(BuildContext context) {
    // WidgetsApp, not MaterialApp: the spike draws every pixel itself, so a
    // Material theme and a Navigator would only be overhead.
    return WidgetsApp(
      color: Palette.base,
      debugShowCheckedModeBanner: false,
      builder: (context, _) => const Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(color: Palette.base, child: GateScreen()),
      ),
    );
  }
}

/// Cold-start instrumentation. t0 lives on the native side (kernel exec time);
/// this only reports the two Dart-side milestones. See MainFlutterWindow.swift.
abstract final class _Instrument {
  static const _channel = MethodChannel('gate/instrument');

  static void arm() {
    var framed = false;
    var painted = false;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (framed) return;
      framed = true;
      _channel.invokeMethod<void>('firstFrame');
    });
    SchedulerBinding.instance.addTimingsCallback((_) {
      if (painted) return;
      painted = true;
      _channel.invokeMethod<void>('firstPaint');
    });
    if (Platform.environment['GATE_FRAMES'] != null) _armFrameStats();
  }

  /// Dropped-frame observation for the meter. Reports every second: how many
  /// frames landed, and how many missed a 60 Hz budget on build or raster.
  static void _armFrameStats() {
    var frames = 0;
    var late = 0;
    var worst = 0.0;
    var since = DateTime.now();
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final t in timings) {
        frames++;
        final ms = t.totalSpan.inMicroseconds / 1000.0;
        if (ms > worst) worst = ms;
        if (ms > 16.7) late++;
      }
      final now = DateTime.now();
      if (now.difference(since).inMilliseconds < 1000) return;
      final secs = now.difference(since).inMilliseconds / 1000.0;
      stdout.writeln(
        'FRAMES fps=${(frames / secs).toStringAsFixed(1)} '
        'late=$late/$frames worst=${worst.toStringAsFixed(1)}ms',
      );
      frames = 0;
      late = 0;
      worst = 0;
      since = now;
    });
  }
}
