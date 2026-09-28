import 'case_model.dart';

class RequesterDashboardModel {
  final int totalCases;
  final int openCases;
  final int awaitingActionCases;
  final int resolvedCases;
  final List<CaseModel> recentCases;

  RequesterDashboardModel({
    required this.totalCases,
    required this.openCases,
    required this.awaitingActionCases,
    required this.resolvedCases,
    required this.recentCases,
  });

  factory RequesterDashboardModel.fromJson(Map<String, dynamic> json) {
    var rawList = json['recent_cases'] as List? ?? [];
    return RequesterDashboardModel(
      totalCases: (json['total_cases'] as num?)?.toInt() ?? 0,
      openCases: (json['open_cases'] as num?)?.toInt() ?? 0,
      awaitingActionCases: (json['awaiting_action_cases'] as num?)?.toInt() ?? 0,
      resolvedCases: (json['resolved_cases'] as num?)?.toInt() ?? 0,
      recentCases: rawList.map((e) => CaseModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class OperatorDashboardModel {
  final int unassignedCount;
  final int myAssignedCount;
  final int highRiskCount;
  final int pendingResolutionCount;
  final List<CaseModel> unassignedCases;
  final List<CaseModel> myCases;
  final List<CaseModel> highRiskCases;

  OperatorDashboardModel({
    required this.unassignedCount,
    required this.myAssignedCount,
    required this.highRiskCount,
    required this.pendingResolutionCount,
    required this.unassignedCases,
    required this.myCases,
    required this.highRiskCases,
  });

  factory OperatorDashboardModel.fromJson(Map<String, dynamic> json) {
    var rawUnassigned = json['unassigned_cases'] as List? ?? [];
    var rawMy = json['my_cases'] as List? ?? [];
    var rawHighRisk = json['high_risk_cases'] as List? ?? [];

    return OperatorDashboardModel(
      unassignedCount: (json['unassigned_count'] as num?)?.toInt() ?? 0,
      myAssignedCount: (json['my_assigned_count'] as num?)?.toInt() ?? 0,
      highRiskCount: (json['high_risk_count'] as num?)?.toInt() ?? 0,
      pendingResolutionCount: (json['pending_resolution_count'] as num?)?.toInt() ?? 0,
      unassignedCases: rawUnassigned.map((e) => CaseModel.fromJson(e as Map<String, dynamic>)).toList(),
      myCases: rawMy.map((e) => CaseModel.fromJson(e as Map<String, dynamic>)).toList(),
      highRiskCases: rawHighRisk.map((e) => CaseModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class SquadWorkload {
  final String teamName;
  final int openCases;
  final int capacity;
  final double utilizationPercentage;

  SquadWorkload({
    required this.teamName,
    required this.openCases,
    required this.capacity,
    required this.utilizationPercentage,
  });

  factory SquadWorkload.fromJson(Map<String, dynamic> json) {
    return SquadWorkload(
      teamName: (json['team_name'] ?? 'Team').toString(),
      openCases: (json['open_cases'] as num?)?.toInt() ?? 0,
      capacity: (json['capacity'] as num?)?.toInt() ?? 10,
      utilizationPercentage: (json['utilization_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ProblemCluster {
  final String title;
  final int caseCount;
  final String category;
  final String suggestedRootCause;

  ProblemCluster({
    required this.title,
    required this.caseCount,
    required this.category,
    required this.suggestedRootCause,
  });

  factory ProblemCluster.fromJson(Map<String, dynamic> json) {
    return ProblemCluster(
      title: (json['title'] ?? '').toString(),
      caseCount: (json['case_count'] as num?)?.toInt() ?? 1,
      category: (json['category'] ?? 'Network').toString(),
      suggestedRootCause: (json['suggested_root_cause'] ?? 'Underlying incident identified').toString(),
    );
  }
}

class ManagerDashboardModel {
  final double slaComplianceRate;
  final double mttrMinutes;
  final double fcrRate;
  final int totalActiveIncidents;
  final List<SquadWorkload> squadWorkloads;
  final List<ProblemCluster> problemClusters;

  ManagerDashboardModel({
    required this.slaComplianceRate,
    required this.mttrMinutes,
    required this.fcrRate,
    required this.totalActiveIncidents,
    required this.squadWorkloads,
    required this.problemClusters,
  });

  factory ManagerDashboardModel.fromJson(Map<String, dynamic> json) {
    var rawSquads = json['squad_workloads'] as List? ?? [];
    var rawClusters = json['problem_clusters'] as List? ?? [];

    return ManagerDashboardModel(
      slaComplianceRate: (json['sla_compliance_rate'] as num?)?.toDouble() ?? 96.4,
      mttrMinutes: (json['mttr_minutes'] as num?)?.toDouble() ?? 42.0,
      fcrRate: (json['fcr_rate'] as num?)?.toDouble() ?? 78.5,
      totalActiveIncidents: (json['total_active_incidents'] as num?)?.toInt() ?? 14,
      squadWorkloads: rawSquads.map((e) => SquadWorkload.fromJson(e as Map<String, dynamic>)).toList(),
      problemClusters: rawClusters.map((e) => ProblemCluster.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
