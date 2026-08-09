import 'dart:async';
import 'dart:io';

import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'audio_meter.dart';
import 'theme.dart';

// --- content (spike copy; edit here) ---------------------------------------
const _claim = ['I am someone who trains', "when I don't feel like it."];
const _promptLead = 'this morning you said:';
const _promptQuote = '"gym after the 4pm shift"';
const _transcript =
    'went after the shift. legs were dead, did the session anyway.';

enum Mark { kept, broken, unsettled }

/// The six days before today, oldest first.
const _history = <Mark>[
  Mark.kept,
  Mark.broken,
  Mark.kept,
  Mark.unsettled,
  Mark.kept,
  Mark.kept,
];

enum Phase { idle, recording, settling, verdict, closing }

const _transcriptDelay = Duration(milliseconds: 400);

/// ~660 ms to full rest with a ~4% overshoot: mass 1, stiffness 220, damping 21
/// gives w0 = 14.8 rad/s and a damping ratio of 0.71.
const _settleSpring = SpringDescription(mass: 1, stiffness: 220, damping: 21);

class GateScreen extends StatefulWidget {
  const GateScreen({super.key});

  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen>
    with SingleTickerProviderStateMixin {
  final _meter = AudioMeter();
  final _rootKey = GlobalKey();
  final _slotKey = GlobalKey();
  final _actionKey = GlobalKey();
  final _seconds = ValueNotifier<int>(0);

  late final AnimationController _fly = AnimationController.unbounded(
    vsync: this,
  );

  Phase _phase = Phase.idle;
  Mark? _today;
  Mark? _flying;
  String? _shown;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;

  final _timers = <Timer>[];
  Timer? _clock;

  void _after(int ms, VoidCallback fn) {
    _timers.add(Timer(Duration(milliseconds: ms), fn));
  }

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  @override
  void initState() {
    super.initState();
    // Measurement hook only: GATE_HOLD=<seconds> holds the button by itself so
    // the meter can be profiled without a hand on the trackpad.
    final hold = int.tryParse(Platform.environment['GATE_HOLD'] ?? '');
    if (hold != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _startHold();
        if (hold > 0) _after(hold * 1000, _endHold);
      });
    }
  }

  @override
  void dispose() {
    _cancelTimers();
    _clock?.cancel();
    _fly.dispose();
    _meter.dispose();
    _seconds.dispose();
    super.dispose();
  }

  // 2. press and hold -------------------------------------------------------
  void _startHold() {
    if (_phase != Phase.idle) return;
    setState(() => _phase = Phase.recording);
    _seconds.value = 0;
    _meter.start();
    _clock = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _seconds.value = _meter.elapsed.inSeconds;
    });
  }

  // 3. release --------------------------------------------------------------
  void _endHold() {
    if (_phase != Phase.recording) return;
    _clock?.cancel();
    _meter.stop();
    setState(() => _phase = Phase.settling);
    _after(_transcriptDelay.inMilliseconds, () {
      if (!mounted) return;
      setState(() {
        _shown = _transcript;
        _phase = Phase.verdict;
      });
    });
  }

  // 4. settle: the day's mark springs into the strip -------------------------
  void _settle(Mark mark) {
    final from = _centreOf(_actionKey);
    final to = _centreOf(_slotKey);
    if (from == null || to == null) {
      setState(() => _today = mark);
      _after(200, () => setState(() => _phase = Phase.closing));
      return;
    }
    setState(() {
      _flying = mark;
      _from = from;
      _to = to;
    });
    _fly.value = 0;
    _fly.animateWith(SpringSimulation(_settleSpring, 0, 1, 0)).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _flying = null;
        _today = mark;
      });
      _after(260, () {
        if (mounted) setState(() => _phase = Phase.closing);
      });
    });
  }

  Offset? _centreOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    final root = _rootKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || root == null || !box.hasSize) return null;
    return root.globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));
  }

  // 5. not tonight: one tap, no confirm -------------------------------------
  void _notTonight() {
    _cancelTimers();
    _clock?.cancel();
    _meter.stop();
    setState(() {
      _today = Mark.unsettled;
      _phase = Phase.closing;
    });
  }

  void _again() {
    _cancelTimers();
    setState(() {
      _today = null;
      _shown = null;
      _flying = null;
      _phase = Phase.idle;
    });
    _seconds.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final closing = _phase == Phase.closing;
    return Stack(
      key: _rootKey,
      children: [
        AnimatedOpacity(
          opacity: closing ? 0 : 1,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOut,
          child: IgnorePointer(
            ignoring: closing,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_strip(), Expanded(child: _body()), _foot()],
            ),
          ),
        ),
        IgnorePointer(
          ignoring: !closing,
          child: AnimatedOpacity(
            opacity: closing ? 1 : 0,
            duration: const Duration(milliseconds: 460),
            curve: Curves.easeOut,
            child: _closingNote(),
          ),
        ),
        if (_flying != null) _flyingMark(),
      ],
    );
  }

  // --- 1. the record strip --------------------------------------------------
  Widget _strip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Metrics.gutter, 34, Metrics.gutter, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_todayLabel(), style: Face.label),
          Row(
            children: [
              for (var i = 0; i < _history.length; i++) ...[
                _MarkDot(mark: _history[i], dim: i < 3),
                const SizedBox(width: Metrics.markGap),
              ],
              SizedBox(
                key: _slotKey,
                width: Metrics.markSize,
                height: Metrics.markSize,
                child: _MarkDot(mark: _today),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- the claim ------------------------------------------------------------
  Widget _body() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Metrics.gutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_claim.join('\n'), style: Face.claim),
          const SizedBox(height: 34),
          Text(_promptLead, style: Face.meta),
          Text(
            _promptQuote,
            style: Face.meta.copyWith(color: Palette.inkContainer),
          ),
          const SizedBox(height: 26),
          // Reserved so the transcript arriving never shifts the claim.
          SizedBox(
            height: 22,
            child: AnimatedOpacity(
              opacity: _shown == null ? 0 : 1,
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOut,
              child: Text(
                _shown ?? '',
                style: Face.meta.copyWith(color: Palette.ash),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- the action ----------------------------------------------------------
  Widget _foot() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 46),
      child: Column(
        children: [
          AnimatedOpacity(
            opacity: _flying == null ? 1 : 0,
            duration: const Duration(milliseconds: 160),
            child: SizedBox(
              height: 88,
              child: Center(
                child: KeyedSubtree(
                  key: _actionKey,
                  child: _phase == Phase.verdict ? _verdicts() : _hold(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _Tappable(
            onTap: _notTonight,
            builder: (hovered) => Text(
              'Not tonight',
              style: Face.meta.copyWith(
                color: hovered ? Palette.mute : Palette.stone,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hold() {
    final live = _phase == Phase.recording;
    return Listener(
      onPointerDown: (_) => _startHold(),
      onPointerUp: (_) => _endHold(),
      onPointerCancel: (_) => _endHold(),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: live ? 470 : 262,
          height: live ? 74 : 56,
          decoration: BoxDecoration(
            color: live ? Palette.container : Palette.containerLow,
            borderRadius: BorderRadius.circular(live ? 37 : 28),
            border: Border.all(
              color: live ? Palette.bright : Palette.outline,
              width: 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                opacity: live ? 0 : 1,
                duration: const Duration(milliseconds: 140),
                child: Text('HOLD TO SPEAK', style: Face.button),
              ),
              AnimatedOpacity(
                opacity: live ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: _meterRow(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 16, 22, 16),
      child: Row(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _BarsPainter(_meter),
              size: Size.infinite,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 34,
            child: ValueListenableBuilder<int>(
              valueListenable: _seconds,
              builder: (_, s, _) => Text(
                '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}',
                style: Face.timer,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verdicts() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _pill('KEPT', () => _settle(Mark.kept)),
        const SizedBox(width: 22),
        _pill('BROKEN', () => _settle(Mark.broken)),
      ],
    );
  }

  Widget _pill(String label, VoidCallback onTap) {
    return _Tappable(
      onTap: onTap,
      builder: (hovered) => Container(
        width: 152,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hovered ? Palette.containerHigh : Palette.containerLow,
          borderRadius: BorderRadius.circular(27),
          border: Border.all(
            color: hovered ? Palette.bright : Palette.outline,
            width: 1,
          ),
        ),
        child: Text(label, style: Face.button),
      ),
    );
  }

  // --- the settle flight ----------------------------------------------------
  Widget _flyingMark() {
    return AnimatedBuilder(
      animation: _fly,
      builder: (_, _) {
        final t = _fly.value;
        final p = Offset.lerp(_from, _to, t)!;
        final scale = 1 + 1.4 * (1 - t);
        return Positioned(
          left: p.dx - 20,
          top: p.dy - 20,
          width: 40,
          height: 40,
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: _MarkDot(mark: _flying),
            ),
          ),
        );
      },
    );
  }

  Widget _closingNote() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('goodnight', style: Face.closing),
          const SizedBox(height: 26),
          // Spike-only: lets the flow be re-run for measurements.
          _Tappable(
            onTap: _again,
            builder: (hovered) => Text(
              'again',
              style: Face.label.copyWith(
                color: hovered ? Palette.mute : Palette.stone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _todayLabel() {
  const days = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];
  const months = [
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER',
  ];
  final d = DateTime.now();
  return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
}

class _MarkDot extends StatelessWidget {
  const _MarkDot({required this.mark, this.dim = false});

  final Mark? mark;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final BoxDecoration decoration;
    switch (mark) {
      case Mark.kept:
        decoration = const BoxDecoration(
          color: Palette.ink,
          shape: BoxShape.circle,
        );
      case Mark.broken:
        decoration = const BoxDecoration(
          color: Palette.stone,
          shape: BoxShape.circle,
        );
      case Mark.unsettled:
        decoration = BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Palette.outline, width: 1.4),
        );
      case null: // today, not yet marked
        decoration = BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Palette.outlineSoft, width: 1.4),
        );
    }
    return Opacity(
      opacity: dim ? 0.45 : 1,
      child: Container(
        width: Metrics.markSize,
        height: Metrics.markSize,
        decoration: decoration,
      ),
    );
  }
}

/// The 40-bar meter. Painted from the ring buffer with `repaint: meter`, so a
/// tick invalidates exactly one RenderObject — no rebuild, no relayout.
class _BarsPainter extends CustomPainter {
  _BarsPainter(this.meter) : super(repaint: meter);

  final AudioMeter meter;

  @override
  void paint(Canvas canvas, Size size) {
    const n = AudioMeter.barCount;
    const barWidth = 4.0;
    const minHeight = 4.0;
    const radius = Radius.circular(2);
    final slot = size.width / n;
    final inset = (slot - barWidth) / 2;
    final mid = size.height / 2;
    final paint = Paint()..isAntiAlias = true;

    for (var i = 0; i < n; i++) {
      final v = meter.levels[i];
      final h = minHeight + (size.height - minHeight) * Curves.easeOut.transform(v);
      paint.color = Color.lerp(Palette.stone, Palette.ink, v)!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * slot + inset, mid - h / 2, barWidth, h),
          radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => false;
}

/// Minimal hover + tap wrapper. The spike has no Material, so this is the
/// whole button system.
class _Tappable extends StatefulWidget {
  const _Tappable({required this.onTap, required this.builder});

  final VoidCallback onTap;
  final Widget Function(bool hovered) builder;

  @override
  State<_Tappable> createState() => _TappableState();
}

class _TappableState extends State<_Tappable> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.builder(_hovered),
      ),
    );
  }
}
