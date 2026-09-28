import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/ai_analysis_model.dart';

class AiProvenanceBanner extends StatelessWidget {
  final AIAnalysisModel analysis;
  final VoidCallback? onAcceptTriage;
  final bool showActions;

  const AiProvenanceBanner({
    super.key,
    required this.analysis,
    this.onAcceptTriage,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final confidencePct = (analysis.confidenceScore * 100).toInt();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.aiVioletLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.aiVioletBorder, width: 1.2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.aiViolet.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.aiViolet,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Gemini 2.5 Flash Autonomous Radar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.aiViolet,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.aiViolet,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$confidencePct% match',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (analysis.sentiment != null)
                      Text(
                        'Detected tone: ${analysis.sentiment}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (showActions && onAcceptTriage != null)
                ElevatedButton.icon(
                  onPressed: onAcceptTriage,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Accept Triage'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.aiViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          if (analysis.reasoningNotes != null && analysis.reasoningNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.aiVioletBorder.withValues(alpha: 0.5)),
              ),
              child: Text(
                analysis.reasoningNotes!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (analysis.suggestedNextSteps.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: analysis.suggestedNextSteps.map((step) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.subdirectory_arrow_right, size: 12, color: AppTheme.aiViolet),
                      const SizedBox(width: 4),
                      Text(
                        step,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
