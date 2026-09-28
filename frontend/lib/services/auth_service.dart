import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AuthState extends ChangeNotifier {
  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null && _token != null;

  String get currentRole => _currentUser?.role ?? 'REQUESTER';

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiClient.post(
        '/auth/login',
        body: {'email': email, 'password': password},
      );

      if (res.success && res.data != null) {
        _token = res.data['access_token']?.toString();
        ApiClient.setToken(_token);
        final rawUser = res.data['user'] is Map<String, dynamic>
            ? (res.data['user'] as Map<String, dynamic>)
            : (res.data as Map<String, dynamic>);
        _currentUser = UserModel.fromJson(rawUser);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res.errorMessage ?? 'Authentication failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> switchDemoRole(String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiClient.post(
        '/auth/demo-login',
        queryParams: {'role': role},
      );

      if (res.success && res.data != null) {
        _token = res.data['access_token']?.toString();
        ApiClient.setToken(_token);
        final rawUser = res.data['user'] is Map<String, dynamic>
            ? (res.data['user'] as Map<String, dynamic>)
            : (res.data as Map<String, dynamic>);
        _currentUser = UserModel.fromJson(rawUser);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res.errorMessage ?? 'Failed to switch persona';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _token = null;
    ApiClient.setToken(null);
    notifyListeners();
  }
}
