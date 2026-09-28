import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/case_model.dart';
import '../models/ai_analysis_model.dart';
import '../services/case_service.dart';
import '../services/ai_service.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/priority_badge.dart';

class CreateCaseScreen extends StatefulWidget {
  const CreateCaseScreen({super.key});

  @override
  State<CreateCaseScreen> createState() => _CreateCaseScreenState();
}

class _CreateCaseScreenState extends State<CreateCaseScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _impact = 'MODERATE';
  String _urgency = 'MEDIUM';
  String? _selectedCategoryId;

  List<CategoryModel> _categories = [];
  AIAnalysisModel? _aiRadar;
  List<DuplicateCandidate> _duplicates = [];
  bool _isAnalyzing = false;
  bool _isSubmitting = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _titleCtrl.addListener(_onTextChanged);
    _descCtrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await CaseService.getCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        if (cats.isNotEmpty) _selectedCategoryId = cats.first.id;
      });
    }
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (title.length > 5 || desc.length > 10) {
      _debounceTimer = Timer(const Duration(milliseconds: 900), () {
        _runAiRadar(title, desc);
      });
    }
  }

  Future<void> _runAiRadar(String title, String desc) async {
    if (title.isEmpty) return;
    setState(() => _isAnalyzing = true);

    try {
      final analysis = await AiService.preTriage(title: title, description: desc);
      final dups = await AiService.detectDuplicates(title: title, description: desc);

      if (mounted) {
        setState(() {
          _aiRadar = analysis;
          _duplicates = dups;
          _isAnalyzing = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _applyAiSuggestion() {
    if (_aiRadar == null) return;
    if (_aiRadar!.predictedCategory != null && _categories.isNotEmpty) {
      final match = _categories.firstWhere(
        (c) => c.name.toLowerCase().contains(_aiRadar!.predictedCategory!.toLowerCase()),
        orElse: () => _categories.first,
      );
      setState(() {
        _selectedCategoryId = match.id;
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Applied Gemini AI triage recommendations'),
        backgroundColor: AppTheme.aiViolet,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide both an incident title and description.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final newCase = await CaseService.createCase(
      title: title,
      description: desc,
      impact: _impact,
      urgency: _urgency,
      categoryId: _selectedCategoryId,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (newCase != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Case ${newCase.caseNumber} submitted successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit case. Please try again.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const TopNavBar(title: 'Report New Incident'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Report New IT Incident',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Adaptive Layout for Mobile / Desktop
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 900;

                final formCard = Card(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 18 : 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Incident Details',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        const Text(
                          'Summary / Title *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _titleCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Wi-Fi disconnection on 4th floor CorpNet-5G',
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Description
                        const Text(
                          'Detailed Description & Symptoms *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _descCtrl,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText: 'Describe what happened, error messages, and affected hardware...',
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Impact & Urgency Row
                        if (isMobile) ...[
                          const Text('Business Impact', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _impact,
                            items: const [
                              DropdownMenuItem(value: 'LOW', child: Text('Low (Single User)')),
                              DropdownMenuItem(value: 'MODERATE', child: Text('Moderate (Workgroup)')),
                              DropdownMenuItem(value: 'SIGNIFICANT', child: Text('Significant (Department)')),
                              DropdownMenuItem(value: 'CRITICAL', child: Text('Critical (Company-wide)')),
                            ],
                            onChanged: (val) => setState(() => _impact = val ?? 'MODERATE'),
                          ),
                          const SizedBox(height: 14),
                          const Text('Urgency', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _urgency,
                            items: const [
                              DropdownMenuItem(value: 'LOW', child: Text('Low')),
                              DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                              DropdownMenuItem(value: 'HIGH', child: Text('High')),
                              DropdownMenuItem(value: 'CRITICAL', child: Text('Critical')),
                            ],
                            onChanged: (val) => setState(() => _urgency = val ?? 'MEDIUM'),
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Business Impact', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      initialValue: _impact,
                                      items: const [
                                        DropdownMenuItem(value: 'LOW', child: Text('Low (Single User)')),
                                        DropdownMenuItem(value: 'MODERATE', child: Text('Moderate (Workgroup)')),
                                        DropdownMenuItem(value: 'SIGNIFICANT', child: Text('Significant (Department)')),
                                        DropdownMenuItem(value: 'CRITICAL', child: Text('Critical (Company-wide)')),
                                      ],
                                      onChanged: (val) => setState(() => _impact = val ?? 'MODERATE'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Urgency', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      initialValue: _urgency,
                                      items: const [
                                        DropdownMenuItem(value: 'LOW', child: Text('Low')),
                                        DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                                        DropdownMenuItem(value: 'HIGH', child: Text('High')),
                                        DropdownMenuItem(value: 'CRITICAL', child: Text('Critical')),
                                      ],
                                      onChanged: (val) => setState(() => _urgency = val ?? 'MEDIUM'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 18),

                        // Category
                        const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategoryId,
                          items: _categories.map((cat) {
                            return DropdownMenuItem(value: cat.id, child: Text(cat.name));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedCategoryId = val),
                        ),
                        const SizedBox(height: 28),

                        // Submit Action
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : _handleSubmit,
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send_rounded, size: 18),
                              label: const Text('Submit Incident Report'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );

                final radarColumn = Column(
                  children: [
                    _buildLiveAiRadarCard(),
                    if (_duplicates.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDuplicateWarningCard(),
                    ],
                  ],
                );

                if (isMobile) {
                  return Column(
                    children: [
                      formCard,
                      const SizedBox(height: 20),
                      radarColumn,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: formCard),
                    const SizedBox(width: 24),
                    Expanded(flex: 4, child: radarColumn),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveAiRadarCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.aiVioletLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.aiVioletBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.aiViolet,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Gemini AI Pre-Triage Radar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.aiViolet,
                    ),
                  ),
                ],
              ),
              if (_isAnalyzing)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(color: AppTheme.aiViolet, strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_aiRadar == null)
            const Text(
              'Type your issue on the left to activate real-time Gemini pre-triage classification, squad routing, and self-service diagnostics.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.aiVioletBorder.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Category: ${_aiRadar!.predictedCategory ?? "Network Connectivity"}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      PriorityBadge(priority: _aiRadar!.predictedPriority ?? 'P2'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Recommended Squad: ${_aiRadar!.predictedTeam ?? "Network Operations"}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            if (_aiRadar!.reasoningNotes != null) ...[
              const SizedBox(height: 12),
              Text(
                _aiRadar!.reasoningNotes!,
                style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.4),
              ),
            ],
            if (_aiRadar!.suggestedNextSteps.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'TRY THESE BEFORE SUBMITTING:',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.4),
              ),
              const SizedBox(height: 6),
              ..._aiRadar!.suggestedNextSteps.map((step) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 14, color: AppTheme.aiViolet),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            step,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _applyAiSuggestion,
                icon: const Icon(Icons.auto_fix_high, size: 14, color: AppTheme.aiViolet),
                label: const Text('Apply AI Recommendations', style: TextStyle(color: AppTheme.aiViolet, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.aiViolet),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDuplicateWarningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 18),
              SizedBox(width: 8),
              Text(
                'Potential Duplicate Detected',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.warning),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Similar incidents already reported by your team:',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          ..._duplicates.map((d) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.warningBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${d.caseNumber}: ${d.title}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${(d.similarityScore * 100).toInt()}% match',
                      style: const TextStyle(fontSize: 10, color: AppTheme.warning, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
