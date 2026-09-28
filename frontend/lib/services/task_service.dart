import '../models/task_model.dart';
import 'api_client.dart';

class TaskService {
  static Future<List<TaskModel>> getTasks(String caseId) async {
    final res = await ApiClient.get<List<TaskModel>>(
      '/cases/$caseId/tasks',
      parser: (json) {
        if (json is List) {
          return json.map((e) => TaskModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
    return res.data ?? [];
  }

  static Future<TaskModel?> createTask(
    String caseId, {
    required String title,
    String? description,
    String taskType = 'INVESTIGATION',
    String? assignedToId,
  }) async {
    final res = await ApiClient.post<TaskModel>(
      '/cases/$caseId/tasks',
      body: {
        'title': title,
        'description': description,
        'task_type': taskType,
        'assigned_to_id': assignedToId,
      },
      parser: (json) => TaskModel.fromJson(json as Map<String, dynamic>),
    );
    return res.data;
  }

  static Future<TaskModel?> completeTask(
    String taskId, {
    required String findings,
    String status = 'COMPLETED',
  }) async {
    final res = await ApiClient.post<TaskModel>(
      '/tasks/$taskId/complete',
      body: {
        'findings': findings,
        'status': status,
      },
      parser: (json) => TaskModel.fromJson(json as Map<String, dynamic>),
    );
    return res.data;
  }

  static Future<Map<String, dynamic>?> runAiInvestigation(String caseId) async {
    final res = await ApiClient.post(
      '/cases/$caseId/investigation',
      body: {},
    );
    return res.data as Map<String, dynamic>?;
  }
}
