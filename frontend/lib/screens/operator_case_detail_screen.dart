import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/case_model.dart';
import '../models/communication_model.dart';
import '../models/task_model.dart';
import '../models/ai_analysis_model.dart';
import '../services/case_service.dart';
import '../services/communication_service.dart';
import '../services/task_service.dart';
import '../services/ai_service.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/status_badge.dart';
import '../widgets/priority_badge.dart';
import '../widgets/lifecycle_stepper.dart';
import '../widgets/sla_countdown_timer.dart';

class OperatorCaseDetailScreen extends StatefulWidget {
  final String caseId;

  const OperatorCaseDetailScreen({super.key, required this.caseId});

  @override
  State<OperatorCaseDetailScreen> createState() => _OperatorCaseDetailScreenState();
}

class _OperatorCaseDetailScreenState extends State<OperatorCaseDetailScreen> {
  CaseModel? _caseItem;
  List<CommunicationModel> _communications = [];
  List<TaskModel> _tasks = [];
  AIAnalysisModel? _aiAnalysis;
  bool _isLoading = true;

  // Composer
  final _messageCtrl = TextEditingController();
  bool _isInternalNote = false;
  bool _isSending = false;

  // AI Copilot
  String _draftType = 'REQUEST_INFO';
  String? _generatedAiDraft;
  bool _isGeneratingDraft = false;
  bool _isRunningDiagnostics = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final c = await CaseService.getCaseById(widget.caseId);
    final comms = await CommunicationService.getCommunications(widget.caseId);
    final tasks = await TaskService.getTasks(widget.caseId);
    final ai = await AiService.getCaseAnalysis(widget.caseId);

    if (mounted) {
      setState(() {
        _caseItem = c;
        _communications = comms;
        _tasks = tasks;
        _aiAnalysis = ai;
        _isLoading = false;
      });
    }
  }

  Future<void> _transitionState(String targetState) async {
    final updated = await CaseService.transitionStatus(widget.caseId, targetState);
    if (mounted && updated != null) {
      setState(() => _caseItem = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status transitioned to $targetState'),
          backgroundColor: AppTheme.primary,
        ),
      );
      _loadAll();
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    if (_isInternalNote) {
      await CommunicationService.sendInternalNote(widget.caseId, text);
    } else {
      await CommunicationService.sendPublicReply(widget.caseId, text);
    }

    if (mounted) {
      setState(() => _isSending = false);
      _messageCtrl.clear();
      _loadAll();
    }
  }

  Future<void> _generateDraft() async {
    setState(() => _isGeneratingDraft = true);
    final draft = await CommunicationService.generateAiDraft(widget.caseId, draftType: _draftType);
    if (mounted) {
      setState(() {
        _generatedAiDraft = draft;
        _isGeneratingDraft = false;
      });
    }
  }

  void _insertDraftToComposer() {
    if (_generatedAiDraft != null) {
      setState(() {
        _messageCtrl.text = _generatedAiDraft!;
        _isInternalNote = false;
      });
    }
  }

  Future<void> _runAutomatedDiagnostics() async {
    setState(() => _isRunningDiagnostics = true);
    await TaskService.runAiInvestigation(widget.caseId);
    if (mounted) {
      setState(() => _isRunningDiagnostics = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Automated diagnostic checklist generated and executed.'),
          backgroundColor: AppTheme.aiViolet,
        ),
      );
      _loadAll();
    }
  }

  Future<void> _completeTask(String taskId) async {
    final findingsCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Complete Investigation Step', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Record test results or configuration findings:', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: findingsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. AP-04 reset completed. RSSI signal normalized to -52dBm.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await TaskService.completeTask(taskId, findings: findingsCtrl.text.trim());
                _loadAll();
              },
              child: const Text('Save & Complete'),
            ),
          ],
        );
      },
    );
  }

  void _showProposeResolutionDialog() {
    final summaryCtrl = TextEditingController(text: 'Re-issued 802.1X enterprise radius cert and restarted AP-04 radio interface.');
    final rootCauseCtrl = TextEditingController(text: 'Expired client certificate on 4th floor radius controller.');
    final stepsCtrl = TextEditingController(text: '1. Re-issued radius certificate\n2. Flushed client DNS and ARP cache\n3. Tested 5GHz handoff');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Propose Incident Resolution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Resolution Summary *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(controller: summaryCtrl, maxLines: 2),
                  const SizedBox(height: 12),
                  const Text('Root Cause Analysis *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(controller: rootCauseCtrl, maxLines: 2),
                  const SizedBox(height: 12),
                  const Text('Remediation Steps Taken', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(controller: stepsCtrl, maxLines: 3),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final summary = summaryCtrl.text.trim();
                if (summary.isEmpty) return;
                Navigator.pop(ctx);
                final success = await CaseService.proposeResolution(
                  widget.caseId,
                  resolutionSummary: summary,
                  rootCause: rootCauseCtrl.text.trim(),
                  stepsTaken: stepsCtrl.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
                );
                if (mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Resolution proposed to requester for sign-off.'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                  _loadAll();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
              child: const Text('Propose to Requester'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: TopNavBar(title: 'Operator Workstation'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_caseItem == null) {
      return Scaffold(
        appBar: const TopNavBar(title: 'Operator Workstation'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Incident ticket not found.'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('MMM d, h:mm a');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: TopNavBar(title: 'Investigation Command Center — Case ${_caseItem!.caseNumber}'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    _caseItem!.caseNumber,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                StatusBadge(status: _caseItem!.status, isLarge: true),
                const SizedBox(width: 10),
                PriorityBadge(priority: _caseItem!.priority),
                const Spacer(),
                SlaCountdownTimer(
                  targetTime: _caseItem!.slaTargetResolutionAt ?? _caseItem!.slaTargetResponseAt,
                  isBreached: _caseItem!.slaBreached,
                ),
                const SizedBox(width: 12),
                if (_caseItem!.status != 'CLOSED' && _caseItem!.status != 'RESOLUTION_PROPOSED')
                  ElevatedButton.icon(
                    onPressed: _showProposeResolutionDialog,
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Propose Resolution'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // Stepper
            LifecycleStepper(currentStatus: _caseItem!.status),

            const SizedBox(height: 16),

            // 3-Column Command Layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column 1: Requester Dossier & State Machine (28%)
                Expanded(
                  flex: 28,
                  child: Column(
                    children: [
                      _buildRequesterDossierCard(dateFormat),
                      const SizedBox(height: 14),
                      _buildStateTransitionCard(),
                      const SizedBox(height: 14),
                      _buildInvestigationTasksCard(),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Column 2: Dual-Stream Timeline & Composer (42%)
                Expanded(
                  flex: 42,
                  child: Column(
                    children: [
                      _buildDualStreamTimeline(dateFormat),
                      const SizedBox(height: 14),
                      _buildMessageComposer(),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Column 3: Gemini AI Copilot Hub (30%)
                Expanded(
                  flex: 30,
                  child: Column(
                    children: [
                      _buildAiCopilotCard(),
                      const SizedBox(height: 14),
                      _buildAiDraftGeneratorCard(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequesterDossierCard(DateFormat dateFormat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('REQUESTER DOSSIER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFF0284C7),
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _caseItem!.createdBy?.fullName ?? 'Alex Rivera',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _caseItem!.createdBy?.email ?? 'requester@company.com',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildDetailLine('Category', _caseItem!.category?.name ?? 'Network Connectivity'),
            _buildDetailLine('Assigned Squad', _caseItem!.assignedTeam?.name ?? 'Network Operations'),
            _buildDetailLine('Impact', _caseItem!.impact),
            _buildDetailLine('Urgency', _caseItem!.urgency),
            _buildDetailLine('SLA Tier', _caseItem!.slaTier),
            _buildDetailLine('Created', dateFormat.format(_caseItem!.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStateTransitionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LIFECYCLE STATE CONTROLS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildTransitionButton('IN_PROGRESS', 'Investigate', Icons.play_arrow_rounded, AppTheme.primary),
                _buildTransitionButton('WAITING_ON_REQUESTER', 'Need Info', Icons.help_outline_rounded, AppTheme.warning),
                _buildTransitionButton('CLOSED', 'Force Close', Icons.lock_outline, AppTheme.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransitionButton(String state, String label, IconData icon, Color color) {
    final isCurrent = _caseItem!.status == state;
    return ElevatedButton.icon(
      onPressed: isCurrent ? null : () => _transitionState(state),
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildInvestigationTasksCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SUB-TASKS & INVESTIGATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5)),
                IconButton(
                  icon: _isRunningDiagnostics
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome, size: 16, color: AppTheme.aiViolet),
                  tooltip: 'Run Automated Investigation Checklist',
                  onPressed: _isRunningDiagnostics ? null : _runAutomatedDiagnostics,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No investigation tasks. Click ✨ above to generate AI diagnostics.', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              )
            else
              ..._tasks.map((t) {
                final isDone = t.status == 'COMPLETED';
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDone ? AppTheme.successLight : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isDone ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isDone,
                        onChanged: isDone ? null : (_) => _completeTask(t.id),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if (t.findings != null)
                              Text('Result: ${t.findings}', style: const TextStyle(fontSize: 10, color: AppTheme.success)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDualStreamTimeline(DateFormat dateFormat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.forum_outlined, size: 18, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text('Dual-Stream Timeline', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
                Row(
                  children: [
                    _buildStreamTag('Public Stream', AppTheme.primaryLight, AppTheme.primary),
                    const SizedBox(width: 6),
                    _buildStreamTag('Internal Notes (Locked)', AppTheme.warningLight, AppTheme.warning),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_communications.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No messages recorded yet.', style: TextStyle(color: AppTheme.textMuted))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _communications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final msg = _communications[idx];
                  final isInternal = msg.visibility == 'INTERNAL';
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isInternal ? AppTheme.warningLight : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isInternal ? AppTheme.warningBorder : AppTheme.border,
                        width: isInternal ? 1.2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                if (isInternal) ...[
                                  const Icon(Icons.lock, size: 12, color: AppTheme.warning),
                                  const SizedBox(width: 4),
                                  const Text('INTERNAL NOTE • ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.warning)),
                                ],
                                Text(
                                  msg.sender?.fullName ?? 'Operator Priya N.',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                if (msg.aiGenerated) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(color: AppTheme.aiVioletLight, borderRadius: BorderRadius.circular(4)),
                                    child: const Text('AI Drafted', style: TextStyle(fontSize: 9, color: AppTheme.aiViolet, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            Text(dateFormat.format(msg.createdAt), style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(msg.content, style: const TextStyle(fontSize: 12, height: 1.4)),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamTag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _buildMessageComposer() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Public Reply (Visible to Requester)', style: TextStyle(fontSize: 11)),
                  selected: !_isInternalNote,
                  onSelected: (val) => setState(() => _isInternalNote = false),
                  selectedColor: AppTheme.primaryLight,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: const Icon(Icons.lock, size: 12, color: AppTheme.warning),
                  label: const Text('Internal Note (IT Squad Only)', style: TextStyle(fontSize: 11)),
                  selected: _isInternalNote,
                  onSelected: (val) => setState(() => _isInternalNote = true),
                  selectedColor: AppTheme.warningLight,
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _messageCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                fillColor: _isInternalNote ? AppTheme.warningLight : Colors.white,
                hintText: _isInternalNote
                    ? 'Write confidential note for IT squad (never scrubbed or visible to requester)...'
                    : 'Compose public message to requester...',
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send, size: 16),
                label: Text(_isInternalNote ? 'Save Internal Note' : 'Send Public Reply'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isInternalNote ? AppTheme.warning : AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiCopilotCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.aiVioletLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.aiVioletBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppTheme.aiViolet, borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text('Gemini 2.5 Flash Copilot', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.aiViolet)),
            ],
          ),
          const SizedBox(height: 10),
          if (_aiAnalysis != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Confidence: ${(_aiAnalysis!.confidenceScore * 100).toInt()}% • Sentiment: ${_aiAnalysis!.sentiment ?? "Urgent"}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.aiViolet)),
                  const SizedBox(height: 4),
                  Text(_aiAnalysis!.reasoningNotes ?? 'Identified 802.1X certificate negotiation failure.', style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                ],
              ),
            ),
          ] else
            const Text('AI radar data loaded for this incident.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildAiDraftGeneratorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI RESPONSE DRAFT GENERATOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _draftType,
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              items: const [
                DropdownMenuItem(value: 'REQUEST_INFO', child: Text('Request Missing Info / Logs', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'TROUBLESHOOTING_STEPS', child: Text('Provide Troubleshooting Steps', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'RESOLUTION_PROPOSAL', child: Text('Draft Resolution Summary', style: TextStyle(fontSize: 12))),
              ],
              onChanged: (val) => setState(() => _draftType = val ?? 'REQUEST_INFO'),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGeneratingDraft ? null : _generateDraft,
                icon: _isGeneratingDraft
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, size: 14),
                label: const Text('Generate AI Draft with Gemini'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.aiViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (_generatedAiDraft != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.aiVioletLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.aiVioletBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_generatedAiDraft!, style: const TextStyle(fontSize: 11, height: 1.4)),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _insertDraftToComposer,
                        icon: const Icon(Icons.copy, size: 12),
                        label: const Text('Insert into Composer', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
