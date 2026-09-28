import 'dart:async';
import 'package:flutter/material.dart';

class SlaCountdownTimer extends StatefulWidget {
  final DateTime? targetTime;
  final bool isBreached;
  final String label;

  const SlaCountdownTimer({
    super.key,
    required this.targetTime,
    this.isBreached = false,
    this.label = 'SLA Target',
  });

  @override
  State<SlaCountdownTimer> createState() => _SlaCountdownTimerState();
}

class _SlaCountdownTimerState extends State<SlaCountdownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updateRemaining());
  }

  @override
  void didUpdateWidget(covariant SlaCountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateRemaining();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    if (widget.targetTime == null) return;
    final now = DateTime.now();
    final diff = widget.targetTime!.difference(now);
    if (mounted) {
      setState(() {
        _remaining = diff;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.targetTime == null) {
      return const SizedBox.shrink();
    }

    final isExpired = _remaining.isNegative || widget.isBreached;
    Color fg;
    Color bg;
    IconData icon;
    String timeText;

    if (isExpired) {
      fg = const Color(0xFFDC2626);
      bg = const Color(0xFFFEF2F2);
      icon = Icons.error_outline_rounded;
      final abs = _remaining.abs();
      timeText = 'Breached by ${abs.inHours}h ${abs.inMinutes.remainder(60)}m';
    } else {
      final inMinutes = _remaining.inMinutes;
      if (inMinutes < 60) {
        fg = const Color(0xFFD97706);
        bg = const Color(0xFFFFFBEB);
        icon = Icons.alarm_rounded;
        timeText = '${inMinutes}m remaining';
      } else {
        fg = const Color(0xFF059669);
        bg = const Color(0xFFECFDF5);
        icon = Icons.timer_outlined;
        final hours = _remaining.inHours;
        final mins = _remaining.inMinutes.remainder(60);
        timeText = '${hours}h ${mins}m left';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            timeText,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
