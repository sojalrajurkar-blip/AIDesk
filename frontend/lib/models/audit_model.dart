class AuditLogModel {
  final String id;
  final String? caseId;
  final String? userId;
  final String userRole;
  final String eventType;
  final String action;
  final String? targetEntity;
  final String? targetId;
  final String sha256Checksum;
  final String? previousHash;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  AuditLogModel({
    required this.id,
    this.caseId,
    this.userId,
    required this.userRole,
    required this.eventType,
    required this.action,
    this.targetEntity,
    this.targetId,
    required this.sha256Checksum,
    this.previousHash,
    required this.createdAt,
    this.metadata,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: (json['id'] ?? '').toString(),
      caseId: json['case_id']?.toString(),
      userId: json['user_id']?.toString(),
      userRole: (json['user_role'] ?? 'SYSTEM').toString(),
      eventType: (json['event_type'] ?? 'SYSTEM_EVENT').toString(),
      action: (json['action'] ?? '').toString(),
      targetEntity: json['target_entity']?.toString(),
      targetId: json['target_id']?.toString(),
      sha256Checksum: (json['sha256_checksum'] ?? '').toString(),
      previousHash: json['previous_hash']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
