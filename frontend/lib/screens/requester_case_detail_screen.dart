import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/case_model.dart';
import '../models/communication_model.dart';
import '../services/case_service.dart';
import '../services/communication_service.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/status_badge.dart';
import '../widgets/priority_badge.dart';
import '../widgets/lifecycle_stepper.dart';
import '../widgets/sla_countdown_timer.dart';

class RequesterCaseDetailScreen extends StatefulWidget {
  final String caseId;

  const RequesterCaseDetailScreen({super.key, required this.caseId});

  @override
  State<RequesterCaseDetailScreen> createState() => _RequesterCaseDetailScreenState();
}

class _RequesterCaseDetailScreenState extends State<RequesterCaseDetailScreen> {
  CaseModel? _caseItem;
  List<CommunicationModel> _communications = [];
  bool _isLoading = true;
  final _replyCtrl = TextEditingController();
  bool _isSending = false;
  int _rating = 5;
  final _feedbackCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCaseDetails();
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCaseDetails() async {
    setState(() => _isLoading = true);
    final c = await CaseService.getCaseById(widget.caseId);
    final comms = await CommunicationService.getCommunications(widget.caseId);

    if (mounted) {
      setState(() {
        _caseItem = c;
        _communications = comms;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    final res = await CommunicationService.sendPublicReply(widget.caseId, text);
    if (mounted) {
      setState(() => _isSending = false);
      if (res != null) {
        _replyCtrl.clear();
        _loadCaseDetails();
      }
    }
  }

  Future<void> _confirmSignOff() async {
    final success = await CaseService.confirmResolution(
      widget.caseId,
      satisfactionRating: _rating,
      feedback: _feedbackCtrl.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Incident closed and sign-off recorded.'),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadCaseDetails();
      }
    }
  }

  void _showReopenDialog() {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reopen Incident Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please explain what is still not working so the IT operator can investigate further:',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'e.g. Wi-Fi reconnected for 5 minutes then dropped again with DNS error...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = reasonCtrl.text.trim();
                if (reason.isEmpty) return;
                Navigator.pop(ctx);
                final success = await CaseService.reopenCase(widget.caseId, reopenReason: reason);
                if (mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Incident reopened and returned to investigation.'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                  _loadCaseDetails();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              child: const Text('Reopen Incident'),
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
        appBar: TopNavBar(title: 'Ticket Details'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_caseItem == null) {
      return Scaffold(
        appBar: const TopNavBar(title: 'Ticket Details'),
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

    final isProposed = _caseItem!.status == 'RESOLUTION_PROPOSED';
    final isClosed = _caseItem!.status == 'CLOSED';
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: TopNavBar(title: 'Case ${_caseItem!.caseNumber}'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
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
              ],
            ),

            const SizedBox(height: 18),

            // 8-Step Lifecycle Stepper
            LifecycleStepper(currentStatus: _caseItem!.status),

            const SizedBox(height: 20),

            // Resolution Proposed Action Card
            if (isProposed) ...[
              _buildResolutionProposedCard(),
              const SizedBox(height: 20),
            ],

            // Main Content Row (Left Ticket Dossier + Right Public Timeline)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Ticket Summary Card
                Expanded(
                  flex: 5,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _caseItem!.title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Reported on ${dateFormat.format(_caseItem!.createdAt)}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          const Divider(height: 24),
                          const Text('DESCRIPTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5)),
                          const SizedBox(height: 8),
                          Text(
                            _caseItem!.description,
                            style: const TextStyle(fontSize: 14, height: 1.5, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 20),
                          _buildDetailRow('Assigned Squad', _caseItem!.assignedTeam?.name ?? 'Network Operations'),
                          _buildDetailRow('Assigned Operator', _caseItem!.assignedTo?.fullName ?? 'Priya N. (IT Operations)'),
                          _buildDetailRow('Impact Level', _caseItem!.impact),
                          _buildDetailRow('Urgency', _caseItem!.urgency),
                          _buildDetailRow('Service Level Target', _caseItem!.slaTier),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                // Right: Scrubbed Public Timeline
                Expanded(
                  flex: 6,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.forum_outlined, size: 18, color: AppTheme.primary),
                              SizedBox(width: 8),
                              Text(
                                'Updates & Communications',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Message stream (Public only)
                          if (_communications.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: Text('No messages yet. The IT squad is reviewing your ticket.', style: TextStyle(color: AppTheme.textMuted)),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _communications.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (ctx, idx) {
                                final msg = _communications[idx];
                                final isOperator = msg.senderRole != 'REQUESTER';
                                return _buildMessageBubble(msg, isOperator);
                              },
                            ),

                          if (!isClosed) ...[
                            const Divider(height: 32),
                            const Text('SEND MESSAGE TO IT OPERATOR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _replyCtrl,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Type your message or reply to requested info...',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: _isSending ? null : _sendReply,
                                icon: _isSending
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.send, size: 16),
                                label: const Text('Send Message'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildResolutionProposedCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.successLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.success, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.task_alt, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resolution Proposed by IT Operations',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.success),
                    ),
                    Text(
                      'Please verify that your issue is resolved and sign off below, or reopen if you are still experiencing trouble.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Rating selector
          Row(
            children: [
              const Text('Rate your resolution experience:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Row(
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(
                      star <= _rating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFEAB308),
                      size: 22,
                    ),
                    onPressed: () => setState(() => _rating = star),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _confirmSignOff,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Confirm Resolution & Close Incident'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _showReopenDialog,
                icon: const Icon(Icons.replay, size: 18, color: AppTheme.error),
                label: const Text('Still Having Issues (Reopen)', style: TextStyle(color: AppTheme.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.error),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(CommunicationModel msg, bool isOperator) {
    final dateFormat = DateFormat('h:mm a');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOperator ? const Color(0xFFF8FAFC) : AppTheme.primaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isOperator ? AppTheme.border : AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isOperator ? AppTheme.primary : const Color(0xFF0284C7),
                    child: Text(
                      isOperator ? 'OP' : 'ME',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    msg.sender?.fullName ?? (isOperator ? 'IT Support' : 'You'),
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
              Text(
                dateFormat.format(msg.createdAt),
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            msg.content,
            style: const TextStyle(fontSize: 13, height: 1.45, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}
