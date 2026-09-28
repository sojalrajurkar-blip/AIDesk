import '../models/dashboard_model.dart';
import 'api_client.dart';

class DashboardService {
  static Future<RequesterDashboardModel?> getRequesterDashboard() async {
    final res = await ApiClient.get<RequesterDashboardModel>(
      '/dashboards/requester',
      parser: (json) => RequesterDashboardModel.fromJson(json as Map<String, dynamic>),
    );
    return res.data;
  }

  static Future<OperatorDashboardModel?> getOperatorDashboard() async {
    final res = await ApiClient.get<OperatorDashboardModel>(
      '/dashboards/operator',
      parser: (json) => OperatorDashboardModel.fromJson(json as Map<String, dynamic>),
    );
    return res.data;
  }

  static Future<ManagerDashboardModel?> getManagerDashboard() async {
    final res = await ApiClient.get<ManagerDashboardModel>(
      '/dashboards/manager',
      parser: (json) => ManagerDashboardModel.fromJson(json as Map<String, dynamic>),
    );
    return res.data;
  }
}
