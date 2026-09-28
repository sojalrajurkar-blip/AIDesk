import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/case_model.dart';
import '../models/dashboard_model.dart';
import '../services/case_service.dart';
import '../services/dashboard_service.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/status_badge.dart';
import '../widgets/priority_badge.dart';
import '../widgets/sla_countdown_timer.dart';
import 'operator_case_detail_screen.dart';

class OperatorDashboardScreen extends StatefulWidget {
  const OperatorDashboardScreen({super.key});

  @override
  State<OperatorDashboardScreen> createState() => _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState extends State<OperatorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  OperatorDashboardModel? _dashboard;
  List<CaseModel> _allCases = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _filterPriority;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final dash = await DashboardService.getOperatorDashboard();
    final cases = await CaseService.getCases();
    if (mounted) {
      setState(() {
        _dashboard = dash;
        _allCases = cases;
        _isLoading = false;
      });
    }
  }

  Future<void> _claimCase(String caseId) async {
    await CaseService.assignCase(caseId);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Case assigned to you successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const TopNavBar(title: 'Operator Command Center'),
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
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Incident Queue & AI Triage Dispatch',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Manage unassigned triage queues, respond to urgent incidents, and monitor live SLAs.',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Refresh Queues'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 4 Pastel KPI Metric Cards
                    Row(
                      children: [
                        _buildKpiCard(
                          'Unassigned Queue',
                          '${_dashboard?.unassignedCount ?? 0}',
                          'Gemini triaged, ready to claim',
                          Icons.inbox_outlined,
                          const Color(0xFF4F46E5),
                          const Color(0xFFEEF2FF),
                        ),
                        const SizedBox(width: 14),
                        _buildKpiCard(
                          'Active In My Queue',
                          '${_dashboard?.myAssignedCount ?? 0}',
                          'Assigned to you',
                          Icons.assignment_ind_outlined,
                          const Color(0xFF0284C7),
                          const Color(0xFFF0F9FF),
                        ),
                        const SizedBox(width: 14),
                        _buildKpiCard(
                          'High SLA Risk',
                          '${_dashboard?.highRiskCount ?? 0}',
                          '< 1 hr or breached',
                          Icons.warning_amber_rounded,
                          const Color(0xFFD97706),
                          const Color(0xFFFFFBEB),
                        ),
                        const SizedBox(width: 14),
                        _buildKpiCard(
                          'Pending Confirmation',
                          '${_dashboard?.pendingResolutionCount ?? 0}',
                          'Resolution proposed to user',
                          Icons.check_circle_outline,
                          const Color(0xFF059669),
                          const Color(0xFFECFDF5),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Tab Navigation & Search Filter
                    Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TabBar(
                                    controller: _tabController,
                                    isScrollable: true,
                                    labelColor: AppTheme.primary,
                                    unselectedLabelColor: AppTheme.textSecondary,
                                    indicatorColor: AppTheme.primary,
                                    indicatorWeight: 3,
                                    tabs: [
                                      Tab(text: 'Unassigned (${_dashboard?.unassignedCount ?? 0})'),
                                      Tab(text: 'My Active (${_dashboard?.myAssignedCount ?? 0})'),
                                      Tab(text: 'SLA Risk (${_dashboard?.highRiskCount ?? 0})'),
                                      Tab(text: 'All Incidents (${_allCases.length})'),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 220,
                                  height: 38,
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      hintText: 'Filter by case # or keyword',
                                      prefixIcon: Icon(Icons.search, size: 16),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                    ),
                                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                DropdownButton<String?>(
                                  value: _filterPriority,
                                  hint: const Text('Priority', style: TextStyle(fontSize: 12)),
                                  underline: const SizedBox(),
                                  items: const [
                                    DropdownMenuItem(value: null, child: Text('All Priorities')),
                                    DropdownMenuItem(value: 'P1', child: Text('P1 Critical')),
                                    DropdownMenuItem(value: 'P2', child: Text('P2 High')),
                                    DropdownMenuItem(value: 'P3', child: Text('P3 Medium')),
                                    DropdownMenuItem(value: 'P4', child: Text('P4 Low')),
                                  ],
                                  onChanged: (val) => setState(() => _filterPriority = val),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),

                          // Tab Views
                          SizedBox(
                            height: 480,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildCaseTable(_dashboard?.unassignedCases ?? []),
                                _buildCaseTable(_dashboard?.myCases ?? []),
                                _buildCaseTable(_dashboard?.highRiskCases ?? []),
                                _buildCaseTable(_allCases),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKpiCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
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
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                  child: Icon(icon, color: color, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseTable(List<CaseModel> list) {
    var filtered = list.where((c) {
      if (_searchQuery.isNotEmpty) {
        final matchNum = c.caseNumber.toLowerCase().contains(_searchQuery);
        final matchTitle = c.title.toLowerCase().contains(_searchQuery);
        if (!matchNum && !matchTitle) return false;
      }
      if (_filterPriority != null && c.priority != _filterPriority) {
        return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text('No incidents matching current queue or filter criteria.', style: TextStyle(color: AppTheme.textMuted)),
      );
    }

    final dateFormat = DateFormat('MMM d, h:mm a');

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, idx) {
        final item = filtered[idx];
        final isUnassigned = item.assignedToId == null;

        return InkWell(
          onTap: () => _openCaseDetail(item.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                // Case Number
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

                // Title & Category
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            item.category?.name ?? 'Network Connectivity',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                          if (item.isTriaged) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.aiVioletLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, size: 10, color: AppTheme.aiViolet),
                                  SizedBox(width: 2),
                                  Text('AI Triaged', style: TextStyle(fontSize: 9, color: AppTheme.aiViolet, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Assigned Squad / Person
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.assignedTo?.fullName ?? (isUnassigned ? 'Unassigned' : 'Assigned'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isUnassigned ? FontWeight.w400 : FontWeight.w600,
                          color: isUnassigned ? AppTheme.textMuted : AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        item.assignedTeam?.name ?? 'Network Operations',
                        style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),

                // Status & Priority
                StatusBadge(status: item.status),
                const SizedBox(width: 10),
                PriorityBadge(priority: item.priority),
                const SizedBox(width: 12),

                // SLA Timer
                SlaCountdownTimer(
                  targetTime: item.slaTargetResolutionAt ?? item.slaTargetResponseAt,
                  isBreached: item.slaBreached,
                ),
                const SizedBox(width: 12),

                // Created At
                Text(
                  dateFormat.format(item.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(width: 12),

                // Quick Action
                if (isUnassigned)
                  ElevatedButton(
                    onPressed: () => _claimCase(item.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Claim'),
                  )
                else
                  const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCaseDetail(String caseId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OperatorCaseDetailScreen(caseId: caseId),
      ),
    );
    _loadData();
  }
}
