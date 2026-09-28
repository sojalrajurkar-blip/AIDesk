import 'user_model.dart';

class TaskModel {
  final String id;
  final String caseId;
  final String title;
  final String? description;
  final String taskType; // INVESTIGATION, ACTION, APPROVAL
  final String status; // PENDING, IN_PROGRESS, COMPLETED, CANCELLED
  final String? assignedToId;
  final String? findings;
  final DateTime? completedAt;
  final DateTime createdAt;
  final UserModel? assignedTo;

  TaskModel({
    required this.id,
    required this.caseId,
    required this.title,
    this.description,
    this.taskType = 'INVESTIGATION',
    this.status = 'PENDING',
    this.assignedToId,
    this.findings,
    this.completedAt,
    required this.createdAt,
    this.assignedTo,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: (json['id'] ?? '').toString(),
      caseId: (json['case_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      taskType: (json['task_type'] ?? 'INVESTIGATION').toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      assignedToId: json['assigned_to_id']?.toString(),
      findings: json['findings']?.toString(),
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      assignedTo: json['assigned_to'] != null ? UserModel.fromJson(json['assigned_to'] as Map<String, dynamic>) : null,
    );
  }
}
