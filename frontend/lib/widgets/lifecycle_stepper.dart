import 'package:flutter/material.dart';
import '../core/theme.dart';

class LifecycleStepper extends StatelessWidget {
  final String currentStatus;

  const LifecycleStepper({super.key, required this.currentStatus});

  static const List<Map<String, String>> steps = [
    {'key': 'NEW', 'label': 'Reported'},
    {'key': 'TRIAGED', 'label': 'AI Triaged'},
    {'key': 'ASSIGNED', 'label': 'Assigned'},
    {'key': 'IN_PROGRESS', 'label': 'Investigating'},
    {'key': 'WAITING_ON_REQUESTER', 'label': 'Info Needed'},
    {'key': 'RESOLUTION_PROPOSED', 'label': 'Resolved'},
    {'key': 'CLOSED', 'label': 'Closed'},
  ];

  int _getStepIndex(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return 0;
      case 'TRIAGED':
        return 1;
      case 'ASSIGNED':
        return 2;
      case 'IN_PROGRESS':
        return 3;
      case 'WAITING_ON_REQUESTER':
        return 4;
      case 'RESOLUTION_PROPOSED':
        return 5;
      case 'CLOSED':
        return 6;
      case 'REOPENED':
        return 3; // back in progress
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getStepIndex(currentStatus);
    final isReopened = currentStatus == 'REOPENED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lifecycle Progression',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              if (isReopened)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.errorLight,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'REOPENED (Returned to Investigation)',
                    style: TextStyle(color: AppTheme.error, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: List.generate(steps.length * 2 - 1, (index) {
                  if (index.isOdd) {
                    final stepBefore = index ~/ 2;
                    final isPassed = stepBefore < currentIndex;
                    return Expanded(
                      child: Container(
                        height: 3,
                        color: isPassed ? AppTheme.primary : AppTheme.border,
                      ),
                    );
                  }

                  final stepIndex = index ~/ 2;
                  final step = steps[stepIndex];
                  final isCompleted = stepIndex < currentIndex;
                  final isCurrent = stepIndex == currentIndex;

                  Color circleBg;
                  Color iconColor;
                  Widget iconWidget;

                  if (isCompleted) {
                    circleBg = AppTheme.primary;
                    iconColor = Colors.white;
                    iconWidget = Icon(Icons.check, size: 12, color: iconColor);
                  } else if (isCurrent) {
                    circleBg = isReopened ? AppTheme.error : AppTheme.primary;
                    iconColor = Colors.white;
                    iconWidget = Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    );
                  } else {
                    circleBg = AppTheme.borderLight;
                    iconColor = AppTheme.textMuted;
                    iconWidget = Text(
                      '${stepIndex + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: circleBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCurrent
                                ? (isReopened ? AppTheme.error : AppTheme.primary)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(child: iconWidget),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step['label']!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isCurrent
                              ? AppTheme.textPrimary
                              : (isCompleted ? AppTheme.textSecondary : AppTheme.textMuted),
                        ),
                      ),
                    ],
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
