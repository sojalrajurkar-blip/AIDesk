import 'package:flutter/material.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (priority.toUpperCase()) {
      case 'P1':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        label = 'P1 CRITICAL';
        icon = Icons.error_rounded;
        break;
      case 'P2':
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        label = 'P2 HIGH';
        icon = Icons.warning_amber_rounded;
        break;
      case 'P3':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        label = 'P3 MEDIUM';
        icon = Icons.info_outline_rounded;
        break;
      case 'P4':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        label = 'P4 LOW';
        icon = Icons.remove_circle_outline_rounded;
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        label = priority;
        icon = Icons.circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
