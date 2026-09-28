import 'user_model.dart';

class CommunicationModel {
  final String id;
  final String caseId;
  final String senderId;
  final String senderRole;
  final String messageType; // PUBLIC_REPLY, INTERNAL_NOTE, SYSTEM_EVENT, AI_DRAFT
  final String visibility; // PUBLIC, INTERNAL, SYSTEM
  final String content;
  final bool aiGenerated;
  final bool aiApproved;
  final DateTime createdAt;
  final UserModel? sender;

  CommunicationModel({
    required this.id,
    required this.caseId,
    required this.senderId,
    required this.senderRole,
    required this.messageType,
    required this.visibility,
    required this.content,
    this.aiGenerated = false,
    this.aiApproved = false,
    required this.createdAt,
    this.sender,
  });

  factory CommunicationModel.fromJson(Map<String, dynamic> json) {
    return CommunicationModel(
      id: (json['id'] ?? '').toString(),
      caseId: (json['case_id'] ?? '').toString(),
      senderId: (json['sender_id'] ?? '').toString(),
      senderRole: (json['sender_role'] ?? 'OPERATOR').toString(),
      messageType: (json['message_type'] ?? 'PUBLIC_REPLY').toString(),
      visibility: (json['visibility'] ?? 'PUBLIC').toString(),
      content: (json['content'] ?? '').toString(),
      aiGenerated: json['ai_generated'] as bool? ?? false,
      aiApproved: json['ai_approved'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      sender: json['sender'] != null ? UserModel.fromJson(json['sender'] as Map<String, dynamic>) : null,
    );
  }
}
