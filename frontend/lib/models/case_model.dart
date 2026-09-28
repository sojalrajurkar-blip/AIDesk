import 'user_model.dart';

class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? defaultPriority;
  final String? defaultTeamId;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.defaultPriority,
    this.defaultTeamId,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      defaultPriority: json['default_priority']?.toString(),
      defaultTeamId: json['default_team_id']?.toString(),
    );
  }
}

class TeamModel {
  final String id;
  final String name;
  final String? description;
  final String? email;

  TeamModel({
    required this.id,
    required this.name,
    this.description,
    this.email,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      email: json['email']?.toString(),
    );
  }
}

class CaseModel {
  final String id;
  final String caseNumber;
  final String title;
  final String description;
  final String? categoryId;
  final String priority;
  final String status;
  final String impact;
  final String urgency;
  final String slaTier;
  final String createdById;
  final String? assignedTeamId;
  final String? assignedToId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? slaTargetResponseAt;
  final DateTime? slaTargetResolutionAt;
  final DateTime? firstRespondedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final bool slaBreached;
  final bool isTriaged;
  final String? triageNotes;
  final CategoryModel? category;
  final TeamModel? assignedTeam;
  final UserModel? assignedTo;
  final UserModel? createdBy;

  CaseModel({
    required this.id,
    required this.caseNumber,
    required this.title,
    required this.description,
    this.categoryId,
    required this.priority,
    required this.status,
    required this.impact,
    required this.urgency,
    required this.slaTier,
    required this.createdById,
    this.assignedTeamId,
    this.assignedToId,
    required this.createdAt,
    this.updatedAt,
    this.slaTargetResponseAt,
    this.slaTargetResolutionAt,
    this.firstRespondedAt,
    this.resolvedAt,
    this.closedAt,
    this.slaBreached = false,
    this.isTriaged = false,
    this.triageNotes,
    this.category,
    this.assignedTeam,
    this.assignedTo,
    this.createdBy,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: (json['id'] ?? '').toString(),
      caseNumber: (json['case_number'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      categoryId: json['category_id']?.toString(),
      priority: (json['priority'] ?? 'P3').toString(),
      status: (json['status'] ?? 'NEW').toString(),
      impact: (json['impact'] ?? 'MODERATE').toString(),
      urgency: (json['urgency'] ?? 'MEDIUM').toString(),
      slaTier: (json['sla_tier'] ?? 'STANDARD').toString(),
      createdById: (json['created_by_id'] ?? '').toString(),
      assignedTeamId: json['assigned_team_id']?.toString(),
      assignedToId: json['assigned_to_id']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      slaTargetResponseAt: json['sla_target_response_at'] != null ? DateTime.tryParse(json['sla_target_response_at'].toString()) : null,
      slaTargetResolutionAt: json['sla_target_resolution_at'] != null ? DateTime.tryParse(json['sla_target_resolution_at'].toString()) : null,
      firstRespondedAt: json['first_responded_at'] != null ? DateTime.tryParse(json['first_responded_at'].toString()) : null,
      resolvedAt: json['resolved_at'] != null ? DateTime.tryParse(json['resolved_at'].toString()) : null,
      closedAt: json['closed_at'] != null ? DateTime.tryParse(json['closed_at'].toString()) : null,
      slaBreached: json['sla_breached'] as bool? ?? false,
      isTriaged: json['is_triaged'] as bool? ?? false,
      triageNotes: json['triage_notes']?.toString(),
      category: json['category'] != null ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>) : null,
      assignedTeam: json['assigned_team'] != null ? TeamModel.fromJson(json['assigned_team'] as Map<String, dynamic>) : null,
      assignedTo: json['assigned_to'] != null ? UserModel.fromJson(json['assigned_to'] as Map<String, dynamic>) : null,
      createdBy: json['created_by'] != null ? UserModel.fromJson(json['created_by'] as Map<String, dynamic>) : null,
    );
  }
}
