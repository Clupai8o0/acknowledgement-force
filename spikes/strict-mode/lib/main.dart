import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Force strict-mode spike.
///
/// Every capability under test is exercised through one MethodChannel
/// (`force/strict`) implemented natively per platform. On desktop the app also
/// opens a loopback HTTP control port so the tests can be driven and captured
/// non-interactively (curl -> method channel -> screenshot).
const channel = MethodChannel('force/strict');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpikeApp());
}

/// Entrypoint for the second engine that lives inside the Android
/// TYPE_APPLICATION_OVERLAY window. Same idea as [gateMain] on macOS.
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: const Color(0xFF0A0A0A),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('THE GATE',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6)),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('Flutter UI · second engine\nTYPE_APPLICATION_OVERLAY',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.amberAccent, fontSize: 16)),
              ),
              const SizedBox(height: 24),
              Builder(
                builder: (ctx) => FilledButton(
                  onPressed: () => const MethodChannel('force/strict')
                      .invokeMethod('hideOverlay'),
                  child: const Text('Not tonight'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Entrypoint for the second engine that lives inside the borderless NSPanel
/// used as the gate. Proves real Flutter UI renders on another app's
/// full-screen Space.
@pragma('vm:entry-point')
void gateMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Container(
        color: const Color(0xFF0A0A0A),
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('THE GATE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8)),
            SizedBox(height: 18),
            Text('Flutter UI, second engine, borderless NSPanel',
                style: TextStyle(color: Colors.amberAccent, fontSize: 22)),
            SizedBox(height: 8),
            Text('level .screenSaver · [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]',
                style: TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        ),
      ),
    ),
  );
}

class EventLog extends ChangeNotifier {
  final List<String> lines = [];
  void add(String s) {
    final now = DateTime.now().toIso8601String().substring(11, 23);
    lines.insert(0, '$now  $s');
    if (lines.length > 200) lines.removeLast();
    notifyListeners();
  }
}

final log = EventLog();

class SpikeApp extends StatefulWidget {
  const SpikeApp({super.key});
  @override
  State<SpikeApp> createState() => _SpikeAppState();
}

class _SpikeAppState extends State<SpikeApp> with WidgetsBindingObserver {
  String banner = 'idle';
  Color bannerColor = const Color(0xFF1A1A1A);
  HttpServer? server;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    channel.setMethodCallHandler(_fromNative);
    _startControlServer();
    log.add('dart: main() started, platform=${Platform.operatingSystem}');
    channel.invokeMethod('info').then((v) => log.add('dart: info=$v')).catchError((e) {
      log.add('dart: info failed $e');
      return null;
    });
  }

  Future<dynamic> _fromNative(MethodCall call) async {
    if (call.method == 'onSystemEvent') {
      final a = Map<String, dynamic>.from(call.arguments as Map);
      log.add('NATIVE EVENT  ${a['name']}  (native clock ${a['at']})');
      setState(() {
        banner = 'EVENT: ${a['name']}';
        bannerColor = const Color(0xFF0B3D2E);
      });
    }
    return null;
  }

  /// AppLifecycleState is the only lifecycle signal pure Dart gets.
  /// Recorded so we can compare its coverage with the native notifications.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    log.add('dart: AppLifecycleState.$state');
  }

  Future<void> _startControlServer() async {
    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8787);
      log.add('dart: control port 127.0.0.1:8787 up');
      server!.listen((req) async {
        final path = req.uri.path.replaceFirst('/', '');
        final args = <String, dynamic>{};
        req.uri.queryParameters.forEach((k, v) {
          if (v == 'true') {
            args[k] = true;
          } else if (v == 'false') {
            args[k] = false;
          } else if (int.tryParse(v) != null) {
            args[k] = int.parse(v);
          } else {
            args[k] = v;
          }
        });
        dynamic out;
        String err = '';
        if (path == 'banner') {
          setState(() {
            banner = args['text']?.toString() ?? '';
            bannerColor = const Color(0xFF3D0B0B);
          });
          out = 'ok';
        } else if (path == 'delayedRaise') {
          final ms = (args['ms'] ?? 5000) as int;
          log.add('dart: scheduling unprompted raise in ${ms}ms');
          Timer(Duration(milliseconds: ms), () async {
            log.add('dart: TIMER FIRED -> raiseToFront');
            final r = await channel.invokeMethod('raiseToFront', args);
            log.add('dart: timer raise result=$r');
            setState(() {
              banner = 'TIMER RAISE: $r';
              bannerColor = const Color(0xFF3D0B0B);
            });
          });
          out = 'scheduled';
        } else {
          try {
            out = await channel.invokeMethod(path, args);
            log.add('dart: $path($args) -> $out');
          } catch (e) {
            err = e.toString();
            log.add('dart: $path($args) THREW $err');
          }
        }
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode({'method': path, 'result': '$out', 'error': err}));
        await req.response.close();
      });
    } catch (e) {
      log.add('dart: control port failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: const Color(0xFF101010),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: bannerColor,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FORCE — STRICT MODE SPIKE',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2)),
                    const SizedBox(height: 6),
                    Text(banner,
                        style: const TextStyle(fontSize: 14, color: Colors.amberAccent)),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: log,
                  builder: (_, __) => ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: log.lines.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(log.lines[i],
                          style: TextStyle(
                              fontFamily: 'Menlo',
                              fontSize: 11,
                              color: log.lines[i].contains('NATIVE EVENT')
                                  ? Colors.greenAccent
                                  : Colors.white70)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
