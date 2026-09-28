import '../models/communication_model.dart';
import 'api_client.dart';

class CommunicationService {
  static Future<List<CommunicationModel>> getCommunications(String caseId) async {
    final res = await ApiClient.get<List<CommunicationModel>>(
      '/cases/$caseId/communications',
      parser: (json) {
        if (json is List) {
          return json.map((e) => CommunicationModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
    return res.data ?? [];
  }

  static Future<CommunicationModel?> sendPublicReply(String caseId, String content) async {
    final res = await ApiClient.post<CommunicationModel>(
      '/cases/$caseId/communications',
      body: {
        'message_type': 'PUBLIC_REPLY',
        'visibility': 'PUBLIC',
        'content': content,
      },
      parser: (json) => CommunicationModel.fromJson(json as Map<String, dynamic>),
    );
    return res.data;
  }

  static Future<CommunicationModel?> sendInternalNote(String caseId, String content) async {
    final res = await ApiClient.post<CommunicationModel>(
      '/cases/$caseId/communications',
      body: {
        'message_type': 'INTERNAL_NOTE',
        'visibility': 'INTERNAL',
        'content': content,
      },
      parser: (json) => CommunicationModel.fromJson(json as Map<String, dynamic>),
    );
    return res.data;
  }

  static Future<String?> generateAiDraft(String caseId, {String draftType = 'REQUEST_INFO'}) async {
    final res = await ApiClient.post(
      '/ai/draft-response',
      body: {
        'case_id': caseId,
        'draft_type': draftType,
      },
    );
    if (res.success && res.data != null) {
      return res.data['draft_text'] as String?;
    }
    return null;
  }
}
