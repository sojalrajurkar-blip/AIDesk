class AppConstants {
  static const String appName = 'DeskAI Operations';
  static const String appTagline = 'Autonomous IT Help Desk';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  // Demo accounts
  static const Map<String, String> demoEmails = {
    'REQUESTER': 'requester@company.com',
    'OPERATOR': 'operator@company.com',
    'TEAM_LEAD': 'teamlead@company.com',
    'MANAGER': 'manager@company.com',
    'ADMIN': 'admin@company.com',
  };
}
