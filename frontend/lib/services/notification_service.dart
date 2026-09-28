import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import 'api_client.dart';

class NotificationService extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiClient.get<List<NotificationModel>>(
        '/notifications',
        parser: (json) {
          if (json is List) {
            return json.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );

      _notifications = res.data ?? [];
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    await ApiClient.put('/notifications/$id/read');
    await fetchNotifications();
  }

  Future<void> markAllAsRead() async {
    await ApiClient.put('/notifications/read-all');
    await fetchNotifications();
  }
}
