import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/audit_model.dart';
import '../services/admin_service.dart';
import '../widgets/top_nav_bar.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  List<AuditLogModel> _logs = [];
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  String? _filterEventType;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await AdminService.getAuditLogs(eventType: _filterEventType, limit: 100);
    final sum = await AdminService.getAuditSummary();
    if (mounted) {
      setState(() {
        _logs = logs;
        _summary = sum;
        _isLoading = false;
      });
    }
  }

  void _showMetadataDialog(AuditLogModel log) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('WORM Event Seal: ${log.eventType}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModalRow('Event Action', log.action),
                  _buildModalRow('Actor Role', log.userRole),
                  _buildModalRow('Target Entity', '${log.targetEntity} (${log.targetId})'),
                  _buildModalRow('Timestamp', log.createdAt.toIso8601String()),
                  const Divider(height: 16),
                  const Text('CRYPTOGRAPHIC SHA-256 CHECKSUM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                    child: SelectableText(log.sha256Checksum, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                  ),
                  if (log.previousHash != null) ...[
                    const SizedBox(height: 8),
                    const Text('PREVIOUS EVENT CHAIN HASH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                      child: SelectableText(log.previousHash!, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        );
      },
    );
  }

  Widget _buildModalRow(String label, String value) {
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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm:ss a');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const TopNavBar(title: 'Cryptographic WORM Audit'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLogs,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Cryptographic WORM Verification Banner
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.verified_user_rounded, color: AppTheme.success, size: 28),
                          ),
                          const SizedBox(width: 18),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Cryptographic WORM Audit Trail Active',
                                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                                    SizedBox(width: 8),
                                    Text('• SHA-256 Sealed', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Write-Once-Read-Many immutable ledger. Every ticket status change, AI triage decision, note, and resolution is cryptographically chained.',
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${_summary?["total_events"] ?? _logs.length} Sealed Events',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                              const Text('100% Tamper Evident', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Filter toolbar
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Immutable Audit Event Ledger', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                Row(
                                  children: [
                                    DropdownButton<String?>(
                                      value: _filterEventType,
                                      hint: const Text('All Event Types', style: TextStyle(fontSize: 12)),
                                      underline: const SizedBox(),
                                      items: const [
                                        DropdownMenuItem(value: null, child: Text('All Events')),
                                        DropdownMenuItem(value: 'CASE_CREATED', child: Text('Case Created')),
                                        DropdownMenuItem(value: 'STATUS_CHANGED', child: Text('Status Changed')),
                                        DropdownMenuItem(value: 'AI_TRIAGE_ACCEPTED', child: Text('AI Triage Accepted')),
                                        DropdownMenuItem(value: 'RESOLUTION_CONFIRMED', child: Text('Resolution Confirmed')),
                                        DropdownMenuItem(value: 'REOPENED', child: Text('Case Reopened')),
                                        DropdownMenuItem(value: 'USER_ROLE_CHANGED', child: Text('User Role Changed')),
                                      ],
                                      onChanged: (val) {
                                        setState(() => _filterEventType = val);
                                        _loadLogs();
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(icon: const Icon(Icons.refresh, size: 18), onPressed: _loadLogs),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (_logs.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(child: Text('No audit events found for selected criteria.')),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _logs.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (ctx, idx) {
                                  final item = _logs[idx];
                                  final checksumPrefix = item.sha256Checksum.length > 12
                                      ? '${item.sha256Checksum.substring(0, 12)}...'
                                      : item.sha256Checksum;

                                  return InkWell(
                                    onTap: () => _showMetadataDialog(item),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _getEventIcon(item.eventType),
                                            size: 18,
                                            color: _getEventColor(item.eventType),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.action,
                                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                                ),
                                                Text(
                                                  'Actor: ${item.userRole} • ${item.eventType}',
                                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'sha256:$checksumPrefix',
                                              style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppTheme.textSecondary),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Text(
                                            dateFormat.format(item.createdAt),
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'CASE_CREATED': return Icons.add_circle_outline;
      case 'STATUS_CHANGED': return Icons.swap_horiz_rounded;
      case 'AI_TRIAGE_ACCEPTED': return Icons.auto_awesome;
      case 'RESOLUTION_CONFIRMED': return Icons.task_alt;
      case 'REOPENED': return Icons.replay;
      case 'USER_ROLE_CHANGED': return Icons.admin_panel_settings_outlined;
      default: return Icons.fingerprint;
    }
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case 'CASE_CREATED': return AppTheme.primary;
      case 'STATUS_CHANGED': return const Color(0xFF0284C7);
      case 'AI_TRIAGE_ACCEPTED': return AppTheme.aiViolet;
      case 'RESOLUTION_CONFIRMED': return AppTheme.success;
      case 'REOPENED': return AppTheme.error;
      case 'USER_ROLE_CHANGED': return AppTheme.warning;
      default: return AppTheme.textSecondary;
    }
  }
}
