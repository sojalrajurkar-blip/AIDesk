class DuplicateCandidate {
  final String caseId;
  final String caseNumber;
  final String title;
  final double similarityScore;
  final String status;

  DuplicateCandidate({
    required this.caseId,
    required this.caseNumber,
    required this.title,
    required this.similarityScore,
    required this.status,
  });

  factory DuplicateCandidate.fromJson(Map<String, dynamic> json) {
    return DuplicateCandidate(
      caseId: (json['case_id'] ?? json['id'] ?? '').toString(),
      caseNumber: (json['case_number'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      similarityScore: (json['similarity_score'] as num?)?.toDouble() ?? 0.0,
      status: (json['status'] ?? 'OPEN').toString(),
    );
  }
}

class AIAnalysisModel {
  final String? caseId;
  final String? predictedCategory;
  final String? predictedPriority;
  final String? predictedTeam;
  final String? sentiment;
  final double sentimentScore;
  final double confidenceScore;
  final String modelVersion;
  final String? reasoningNotes;
  final List<String> suggestedNextSteps;
  final List<String> suggestedInvestigationSteps;
  final List<DuplicateCandidate> duplicates;

  AIAnalysisModel({
    this.caseId,
    this.predictedCategory,
    this.predictedPriority,
    this.predictedTeam,
    this.sentiment,
    this.sentimentScore = 0.0,
    this.confidenceScore = 0.85,
    this.modelVersion = 'gemini-2.5-flash',
    this.reasoningNotes,
    this.suggestedNextSteps = const [],
    this.suggestedInvestigationSteps = const [],
    this.duplicates = const [],
  });

  factory AIAnalysisModel.fromJson(Map<String, dynamic> json) {
    var rawNext = json['suggested_next_steps'];
    List<String> nextSteps = [];
    if (rawNext is List) {
      nextSteps = rawNext.map((e) => e.toString()).toList();
    }

    var rawInv = json['suggested_investigation_steps'];
    List<String> invSteps = [];
    if (rawInv is List) {
      invSteps = rawInv.map((e) => e.toString()).toList();
    }

    var rawDup = json['duplicates'] ?? json['potential_duplicates'];
    List<DuplicateCandidate> dups = [];
    if (rawDup is List) {
      dups = rawDup.map((e) => DuplicateCandidate.fromJson(e as Map<String, dynamic>)).toList();
    }

    return AIAnalysisModel(
      caseId: json['case_id']?.toString(),
      predictedCategory: json['predicted_category']?.toString(),
      predictedPriority: json['predicted_priority']?.toString(),
      predictedTeam: json['predicted_team']?.toString(),
      sentiment: json['sentiment']?.toString(),
      sentimentScore: (json['sentiment_score'] as num?)?.toDouble() ?? 0.0,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.85,
      modelVersion: (json['model_version'] ?? 'gemini-2.5-flash').toString(),
      reasoningNotes: json['reasoning_notes']?.toString(),
      suggestedNextSteps: nextSteps,
      suggestedInvestigationSteps: invSteps,
      duplicates: dups,
    );
  }
}
