import 'dart:developer' as developer;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'shell.dart';
import 'theme.dart';

/// `--dart-define=FPSLOG=1` prints frame build/raster percentiles every 5 s.
/// Eyeballing smoothness is worthless as evidence; this is the number.
const _fpsLog = bool.fromEnvironment('FPSLOG');

void _installFrameLog() {
  final build = <int>[];
  final raster = <int>[];
  var lastReport = DateTime.now();
  var over8 = 0, over16 = 0, total = 0;

  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final t in timings) {
      final b = t.buildDuration.inMicroseconds;
      final r = t.rasterDuration.inMicroseconds;
      build.add(b);
      raster.add(r);
      // totalSpan includes the wait for vsync, so it is ~one frame interval
      // even when the frame was free. The budget question is build + raster.
      final work = b + r;
      total++;
      if (work > 8333) over8++;
      if (work > 16667) over16++;
    }
    final now = DateTime.now();
    if (now.difference(lastReport).inSeconds < 5 || build.isEmpty) return;
    lastReport = now;
    build.sort();
    raster.sort();
    int pct(List<int> v, double p) => v[(v.length * p).clamp(0, v.length - 1).toInt()];
    developer.log(
      'FRAMES n=$total '
      'build p50=${pct(build, .5) / 1000}ms p95=${pct(build, .95) / 1000}ms '
      'max=${build.last / 1000}ms | '
      'raster p50=${pct(raster, .5) / 1000}ms p95=${pct(raster, .95) / 1000}ms '
      'max=${raster.last / 1000}ms | '
      'over8.3ms=$over8 over16.7ms=$over16',
      name: 'perf',
    );
    debugPrint(
      '[perf] n=$total build p50=${pct(build, .5) / 1000} p95=${pct(build, .95) / 1000} '
      'max=${build.last / 1000} | raster p50=${pct(raster, .5) / 1000} '
      'p95=${pct(raster, .95) / 1000} max=${raster.last / 1000} | '
      '>8.3ms=$over8 >16.7ms=$over16',
    );
    build.clear();
    raster.clear();
    over8 = 0;
    over16 = 0;
    total = 0;
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (_fpsLog) _installFrameLog();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Palette.base,
    ),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ForceShowcase());
}

/// No MaterialApp, no CupertinoApp. Force uses neither design system, and both
/// put an InheritedWidget lookup on the path of every Text in the tree.
/// WidgetsApp is the whole shell it needs.
class ForceShowcase extends StatelessWidget {
  const ForceShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: Palette.base,
      title: 'Force',
      debugShowCheckedModeBanner: false,
      textStyle: Face.body,
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (c, _, _) => builder(c),
          ),
      home: const Shell(),
    );
  }
}
