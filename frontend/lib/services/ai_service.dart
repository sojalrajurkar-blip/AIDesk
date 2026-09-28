import '../models/ai_analysis_model.dart';
import 'api_client.dart';

class AiService {
  static Future<AIAnalysisModel?> preTriage({
    required String title,
    required String description,
  }) async {
    final res = await ApiClient.post<AIAnalysisModel>(
      '/ai/triage',
      body: {
        'title': title,
        'description': description,
      },
      parser: (json) => AIAnalysisModel.fromJson(json as Map<String, dynamic>),
    );
    return res.data;
  }

  static Future<List<DuplicateCandidate>> detectDuplicates({
    required String title,
    required String description,
  }) async {
    final res = await ApiClient.post<List<DuplicateCandidate>>(
      '/ai/detect-duplicates',
      body: {
        'title': title,
        'description': description,
      },
      parser: (json) {
        if (json is List) {
          return json.map((e) => DuplicateCandidate.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
    return res.data ?? [];
  }

  static Future<AIAnalysisModel?> getCaseAnalysis(String caseId) async {
    final res = await ApiClient.get<AIAnalysisModel>(
      '/cases/$caseId/ai-analysis',
      parser: (json) => AIAnalysisModel.fromJson(json as Map<String, dynamic>),
    );
    return res.data;
  }
}
