import '../models/case_model.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class CaseService {
  static Future<List<CaseModel>> getCases({
    String? status,
    String? priority,
    String? assignedTeamId,
    String? assignedToId,
    bool? unassignedOnly,
    String? search,
  }) async {
    final query = <String, dynamic>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (priority != null && priority.isNotEmpty) query['priority'] = priority;
    if (assignedTeamId != null) query['assigned_team_id'] = assignedTeamId;
    if (assignedToId != null) query['assigned_to_id'] = assignedToId;
    if (unassignedOnly != null) query['unassigned_only'] = unassignedOnly;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final res = await ApiClient.get<List<CaseModel>>(
      '/cases',
      queryParams: query,
      parser: (json) {
        if (json is List) {
          return json.map((e) => CaseModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
    return res.data ?? [];
  }

  static Future<CaseModel?> getCaseById(String caseId) async {
    final res = await ApiClient.get<CaseModel>(
      '/cases/$caseId',
      parser: (json) => CaseModel.fromJson(json as Map<String, dynamic>),
    );
    return res.data;
  }

  static Future<CaseModel?> createCase({
    required String title,
    required String description,
    String impact = 'MODERATE',
    String urgency = 'MEDIUM',
    String? categoryId,
  }) async {
    final res = await ApiClient.post<CaseModel>(
      '/cases',
      body: {
        'title': title,
        'description': description,
        'impact': impact,
        'urgency': urgency,
        'category_id': categoryId,
      },
      parser: (json) => CaseModel.fromJson(json as Map<String, dynamic>),
    );
    return res.data;
  }

  static Future<CaseModel?> transitionStatus(
    String caseId,
    String targetStatus, {
    String? reason,
  }) async {
    final res = await ApiClient.post<CaseModel>(
      '/cases/$caseId/transition',
      body: {
        'target_status': targetStatus,
        'reason': reason,
      },
      parser: (json) => CaseModel.fromJson(json as Map<String, dynamic>),
    );
    return res.data;
  }

  static Future<CaseModel?> assignCase(
    String caseId, {
    String? assignedToId,
    String? assignedTeamId,
  }) async {
    final res = await ApiClient.post<CaseModel>(
      '/cases/$caseId/assign',
      body: {
        'assigned_to_id': assignedToId,
        'assigned_team_id': assignedTeamId,
      },
      parser: (json) => CaseModel.fromJson(json as Map<String, dynamic>),
    );
    return res.data;
  }

  static Future<CaseModel?> applyAiTriage(
    String caseId, {
    String? categoryId,
    String? priority,
    String? assignedTeamId,
    String? notes,
  }) async {
    final res = await ApiClient.post<CaseModel>(
      '/cases/$caseId/triage',
      body: {
        'category_id': categoryId,
        'priority': priority,
        'assigned_team_id': assignedTeamId,
        'triage_notes': notes,
      },
      parser: (json) => CaseModel.fromJson(json as Map<String, dynamic>),
    );
    return res.data;
  }

  static Future<bool> proposeResolution(
    String caseId, {
    required String resolutionSummary,
    String? rootCause,
    List<String>? stepsTaken,
    String? knowledgeArticleId,
  }) async {
    final res = await ApiClient.post(
      '/cases/$caseId/propose-resolution',
      body: {
        'resolution_summary': resolutionSummary,
        'root_cause': rootCause,
        'steps_taken': stepsTaken ?? [],
        'knowledge_article_id': knowledgeArticleId,
      },
    );
    return res.success;
  }

  static Future<bool> confirmResolution(
    String caseId, {
    int? satisfactionRating,
    String? feedback,
  }) async {
    final res = await ApiClient.post(
      '/cases/$caseId/confirm-resolution',
      body: {
        'satisfaction_rating': satisfactionRating ?? 5,
        'feedback': feedback,
      },
    );
    return res.success;
  }

  static Future<bool> reopenCase(
    String caseId, {
    required String reopenReason,
  }) async {
    final res = await ApiClient.post(
      '/cases/$caseId/reopen',
      body: {
        'reopen_reason': reopenReason,
      },
    );
    return res.success;
  }

  static Future<List<CategoryModel>> getCategories() async {
    final res = await ApiClient.get<List<CategoryModel>>(
      '/admin/categories',
      parser: (json) {
        if (json is List) {
          return json.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
    return res.data ?? [];
  }

  static Future<List<TeamModel>> getTeams() async {
    final res = await ApiClient.get<List<TeamModel>>(
      '/admin/teams',
      parser: (json) {
        if (json is List) {
          return json.map((e) => TeamModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
    return res.data ?? [];
  }

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
}
