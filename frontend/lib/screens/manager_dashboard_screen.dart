import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';
import '../widgets/top_nav_bar.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  ManagerDashboardModel? _dashboard;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await DashboardService.getManagerDashboard();
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
      appBar: const TopNavBar(title: 'Directorate SLA & Operational Insights'),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Executive Operational Intelligence',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Real-time SLA breach radar, MTTR velocity, squad capacity allocations, and AI problem clusters.',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 4 KPI Cards
                    Row(
                      children: [
                        _buildKpiTile(
                          'SLA Compliance',
                          '${_dashboard?.slaComplianceRate.toStringAsFixed(1) ?? "96.4"}%',
                          '+1.8% vs last week',
                          Icons.verified_outlined,
                          AppTheme.success,
                          AppTheme.successLight,
                        ),
                        const SizedBox(width: 14),
                        _buildKpiTile(
                          'Mean Time to Resolve',
                          '${_dashboard?.mttrMinutes.toStringAsFixed(0) ?? "42"} min',
                          '-12m faster MTTR',
                          Icons.timer_outlined,
                          AppTheme.primary,
                          AppTheme.primaryLight,
                        ),
                        const SizedBox(width: 14),
                        _buildKpiTile(
                          'First-Contact Resolution',
                          '${_dashboard?.fcrRate.toStringAsFixed(1) ?? "78.5"}%',
                          '78.5% resolved on L1 triage',
                          Icons.handshake_outlined,
                          const Color(0xFF0284C7),
                          const Color(0xFFF0F9FF),
                        ),
                        const SizedBox(width: 14),
                        _buildKpiTile(
                          'Active Incidents',
                          '${_dashboard?.totalActiveIncidents ?? 14}',
                          'Distributed across 5 squads',
                          Icons.bolt_outlined,
                          AppTheme.warning,
                          AppTheme.warningLight,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Middle Row: Squad Workload Bars + AI Problem Cluster Radar
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Squad Capacity Utilization
                        Expanded(
                          flex: 5,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Squad Workload & Capacity Utilization',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_dashboard != null && _dashboard!.squadWorkloads.isNotEmpty)
                                    ..._dashboard!.squadWorkloads.map((s) => _buildSquadBar(s))
                                  else ...[
                                    _buildSquadBar(SquadWorkload(teamName: 'Network Operations', openCases: 6, capacity: 10, utilizationPercentage: 60)),
                                    _buildSquadBar(SquadWorkload(teamName: 'Endpoint & Hardware', openCases: 4, capacity: 8, utilizationPercentage: 50)),
                                    _buildSquadBar(SquadWorkload(teamName: 'Cloud Infrastructure', openCases: 2, capacity: 6, utilizationPercentage: 33)),
                                    _buildSquadBar(SquadWorkload(teamName: 'Security Operations', openCases: 1, capacity: 5, utilizationPercentage: 20)),
                                    _buildSquadBar(SquadWorkload(teamName: 'Identity & Access', openCases: 3, capacity: 6, utilizationPercentage: 50)),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 20),

                        // Right: Gemini AI Problem Cluster Detector
                        Expanded(
                          flex: 5,
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: AppTheme.aiVioletLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.aiVioletBorder, width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.hub_outlined, color: AppTheme.aiViolet, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Gemini AI Problem Cluster Radar',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.aiViolet),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Unsupervised clustering detecting underlying widespread root causes:',
                                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 14),
                                if (_dashboard != null && _dashboard!.problemClusters.isNotEmpty)
                                  ..._dashboard!.problemClusters.map((c) => _buildClusterCard(c))
                                else ...[
                                  _buildClusterCard(
                                    ProblemCluster(
                                      title: '4th Floor Wi-Fi AP-04 Radius Certificate Flapping',
                                      caseCount: 4,
                                      category: 'Network Operations',
                                      suggestedRootCause: 'Expired SSL radius certificate on controller AP-04 causing client de-auth.',
                                    ),
                                  ),
                                  _buildClusterCard(
                                    ProblemCluster(
                                      title: 'macOS Sonoma GlobalProtect DNS Tunnel Drop',
                                      caseCount: 2,
                                      category: 'Endpoint Systems',
                                      suggestedRootCause: 'Virtual adapter MTU mismatch after OS 14.5 security update.',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKpiTile(String title, String value, String subtitle, IconData icon, Color color, Color bg) {
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
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)), child: Icon(icon, color: color, size: 18)),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildSquadBar(SquadWorkload squad) {
    final pct = squad.utilizationPercentage / 100.0;
    Color barColor = AppTheme.primary;
    if (pct > 0.8) {
      barColor = AppTheme.error;
    } else if (pct > 0.6) {
      barColor = AppTheme.warning;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(squad.teamName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('${squad.openCases} / ${squad.capacity} cases (${squad.utilizationPercentage.toInt()}%)', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: AppTheme.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClusterCard(ProblemCluster cluster) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
              Expanded(
                child: Text(
                  cluster.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.errorLight, borderRadius: BorderRadius.circular(4)),
                child: Text('${cluster.caseCount} linked', style: const TextStyle(fontSize: 10, color: AppTheme.error, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(cluster.suggestedRootCause, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.35)),
        ],
      ),
    );
  }
}
