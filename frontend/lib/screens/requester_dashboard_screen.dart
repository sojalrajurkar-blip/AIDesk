import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/case_model.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/status_badge.dart';
import '../widgets/priority_badge.dart';
import 'create_case_screen.dart';
import 'requester_case_detail_screen.dart';

class RequesterDashboardScreen extends StatefulWidget {
  const RequesterDashboardScreen({super.key});

  @override
  State<RequesterDashboardScreen> createState() => _RequesterDashboardScreenState();
}

class _RequesterDashboardScreenState extends State<RequesterDashboardScreen> {
  RequesterDashboardModel? _dashboard;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await DashboardService.getRequesterDashboard();
    if (mounted) {
      setState(() {
        _dashboard = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const TopNavBar(title: 'Requester Portal'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action Required Banner (If any case is in RESOLUTION_PROPOSED or WAITING_ON_REQUESTER)
                    if (_hasActionRequiredCase())
                      _buildActionRequiredBanner(),

                    const SizedBox(height: 16),

                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My IT Requests & Incidents',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Track real-time progress, provide requested details, or test automated diagnostics.',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final created = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreateCaseScreen()),
                            );
                            if (created == true) _loadData();
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Report New Incident'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 4 Self-Service Diagnostic Cards (Responsive)
                    const Text(
                      'INSTANT SELF-SERVICE DIAGNOSTICS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 900;
                        final cards = [
                          _buildSelfServiceTile(
                            'Wi-Fi Certificate Re-issue',
                            'CorpNet-5G automated cert refresh',
                            Icons.wifi_tethering,
                            const Color(0xFF0284C7),
                          ),
                          _buildSelfServiceTile(
                            'GlobalProtect VPN Reset',
                            'Flush DNS & reset tunnel adapter',
                            Icons.vpn_key_outlined,
                            const Color(0xFF7C3AED),
                          ),
                          _buildSelfServiceTile(
                            'SSO / Password Unlock',
                            'Self-service Okta MFA sync',
                            Icons.password_rounded,
                            const Color(0xFF059669),
                          ),
                          _buildSelfServiceTile(
                            'Slack / Zoom License Sync',
                            'Automated enterprise workspace add',
                            Icons.apps_rounded,
                            const Color(0xFFD97706),
                          ),
                        ];

                        if (isMobile) {
                          return GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.4,
                            children: cards,
                          );
                        }

                        return Row(
                          children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    // Metric Stats Row (Responsive)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 900;
                        final pills = [
                          _buildStatTile('Total Tickets', '${_dashboard?.totalCases ?? 0}', Colors.blueGrey),
                          _buildStatTile('Open & Investigating', '${_dashboard?.openCases ?? 0}', AppTheme.primary),
                          _buildStatTile('Action Required', '${_dashboard?.awaitingActionCases ?? 0}', AppTheme.warning),
                          _buildStatTile('Resolved', '${_dashboard?.resolvedCases ?? 0}', AppTheme.success),
                        ];

                        if (isMobile) {
                          return GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 2.2,
                            children: pills,
                          );
                        }

                        return Row(
                          children: pills.map((p) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: p))).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Cases Table
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Active & Past Incident Reports',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 18),
                                  onPressed: _loadData,
                                  tooltip: 'Refresh Tickets',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_dashboard == null || _dashboard!.recentCases.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                  child: Text('No tickets found. Report an issue to get started.'),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _dashboard!.recentCases.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (ctx, idx) {
                                  final item = _dashboard!.recentCases[idx];
                                  return _buildCaseListItem(item);
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

  bool _hasActionRequiredCase() {
    if (_dashboard == null) return false;
    return _dashboard!.recentCases.any((c) =>
        c.status == 'RESOLUTION_PROPOSED' || c.status == 'WAITING_ON_REQUESTER');
  }

  Widget _buildActionRequiredBanner() {
    final actionCase = _dashboard!.recentCases.firstWhere(
      (c) => c.status == 'RESOLUTION_PROPOSED' || c.status == 'WAITING_ON_REQUESTER',
    );
    final isResolution = actionCase.status == 'RESOLUTION_PROPOSED';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isResolution ? AppTheme.successLight : AppTheme.warningLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isResolution ? AppTheme.success.withValues(alpha: 0.4) : AppTheme.warningBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isResolution ? Icons.check_circle_outline : Icons.pending_actions_rounded,
            color: isResolution ? AppTheme.success : AppTheme.warning,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isResolution
                      ? 'Resolution Proposed for Case ${actionCase.caseNumber}'
                      : 'More Information Needed for Case ${actionCase.caseNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isResolution ? AppTheme.success : AppTheme.warning,
                  ),
                ),
                Text(
                  isResolution
                      ? 'IT Operator Priya N. has marked this issue resolved. Please review and confirm sign-off or reopen.'
                      : 'IT Operations needs additional logs or details to proceed with your ticket.',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _openCaseDetail(actionCase.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: isResolution ? AppTheme.success : AppTheme.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(isResolution ? 'Review & Confirm' : 'View Request'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfServiceTile(String title, String subtitle, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Triggered self-service action: $title'),
            backgroundColor: color,
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildCaseListItem(CaseModel item) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    return InkWell(
      onTap: () => _openCaseDetail(item.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.caseNumber,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Category: ${item.category?.name ?? "General"} • Assigned: ${item.assignedTeam?.name ?? "Network Ops"}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            StatusBadge(status: item.status),
            const SizedBox(width: 12),
            PriorityBadge(priority: item.priority),
            const SizedBox(width: 16),
            Text(
              dateFormat.format(item.createdAt),
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  void _openCaseDetail(String caseId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequesterCaseDetailScreen(caseId: caseId),
      ),
    );
    _loadData();
  }
}
