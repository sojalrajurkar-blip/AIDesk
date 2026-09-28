class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? teamId;
  final String? teamName;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.teamId,
    this.teamName,
    this.avatarUrl,
    this.isActive = true,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['user_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fullName: (json['full_name'] ?? json['fullName'] ?? '').toString(),
      role: (json['role'] ?? 'REQUESTER').toString(),
      teamId: json['team_id']?.toString(),
      teamName: json['team_name']?.toString() ?? json['team']?['name']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'team_id': teamId,
      'team_name': teamName,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
