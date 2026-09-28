import '../models/user_model.dart';
import '../models/audit_model.dart';
import 'api_client.dart';

class AdminService {
  static Future<List<UserModel>> getUsers() async {
    final res = await ApiClient.get<List<UserModel>>(
      '/admin/users',
      parser: (json) {
        if (json is List) {
          return json.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
    return res.data ?? [];
  }

  static Future<UserModel?> updateUserRole(String userId, String role) async {
    final res = await ApiClient.put<UserModel>(
      '/admin/users/$userId/role',
      queryParams: {'role': role},
      parser: (json) => UserModel.fromJson(json as Map<String, dynamic>),
    );
    return res.data;
  }

  static Future<List<AuditLogModel>> getAuditLogs({
    String? caseId,
    String? userId,
    String? eventType,
    int limit = 50,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (caseId != null && caseId.isNotEmpty) query['case_id'] = caseId;
    if (userId != null && userId.isNotEmpty) query['user_id'] = userId;
    if (eventType != null && eventType.isNotEmpty) query['event_type'] = eventType;

    final res = await ApiClient.get<List<AuditLogModel>>(
      '/admin/audit-logs',
      queryParams: query,
      parser: (json) {
        if (json is List) {
          return json.map((e) => AuditLogModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
    return res.data ?? [];
  }

  static Future<Map<String, dynamic>?> getAuditSummary() async {
    final res = await ApiClient.get(
      '/admin/audit-summary',
    );
    return res.data as Map<String, dynamic>?;
  }
}
