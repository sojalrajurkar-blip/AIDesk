import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? errorMessage;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.errorMessage,
    required this.statusCode,
  });
}

class ApiClient {
  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  static String? get token => _token;

  static Map<String, String> _headers([Map<String, String>? extra]) {
    final map = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_token';
    }
    if (extra != null) {
      map.addAll(extra);
    }
    return map;
  }

  static Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    T Function(dynamic json)? parser,
  }) async {
    try {
      var uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(
          queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())),
        );
      }

      final response = await http
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 10));
      return _handleResponse<T>(response, parser);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        errorMessage: 'Network error: $e',
        statusCode: 500,
      );
    }
  }

  static Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    dynamic body,
    T Function(dynamic json)? parser,
  }) async {
    try {
      var uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(
          queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())),
        );
      }
      final response = await http
          .post(
            uri,
            headers: _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 12));
      return _handleResponse<T>(response, parser);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        errorMessage: 'Network error: $e',
        statusCode: 500,
      );
    }
  }

  static Future<ApiResponse<T>> put<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    dynamic body,
    T Function(dynamic json)? parser,
  }) async {
    try {
      var uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(
          queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())),
        );
      }
      final response = await http
          .put(
            uri,
            headers: _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 12));
      return _handleResponse<T>(response, parser);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        errorMessage: 'Network error: $e',
        statusCode: 500,
      );
    }
  }

  static Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    T Function(dynamic json)? parser,
  }) async {
    try {
      var uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(
          queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())),
        );
      }
      final response = await http
          .delete(uri, headers: _headers())
          .timeout(const Duration(seconds: 10));
      return _handleResponse<T>(response, parser);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        errorMessage: 'Network error: $e',
        statusCode: 500,
      );
    }
  }

  static ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic json)? parser,
  ) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return ApiResponse<T>(
            success: true,
            data: null,
            statusCode: response.statusCode,
          );
        }
        final decoded = jsonDecode(response.body);
        final data = parser != null ? parser(decoded) : (decoded as T?);
        return ApiResponse<T>(
          success: true,
          data: data,
          statusCode: response.statusCode,
        );
      } else {
        String errorMsg = 'HTTP ${response.statusCode}';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('detail')) {
            errorMsg = errorBody['detail'].toString();
          }
        } catch (_) {}
        return ApiResponse<T>(
          success: false,
          errorMessage: errorMsg,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        errorMessage: 'Parsing error: $e',
        statusCode: response.statusCode,
      );
    }
  }
}
