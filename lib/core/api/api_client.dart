import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_endpoints.dart';

class ApiClient {
  final http.Client _client = http.Client();

  void _logRequest(String method, Uri url, {dynamic body}) {
    // Keep request logging centralized so every API call is traceable.
    print('API REQUEST: $method $url');
    if (body != null) {
      final encodedBody = body is String ? body : jsonEncode(body);
      print('API REQUEST BODY: $encodedBody');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<http.Response> post(String endpoint, dynamic data) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');

    try {
      _logRequest('POST', url, body: data);
      final response = await _client.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');

    try {
      _logRequest('GET', url);
      final response = await _client.get(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> put(String endpoint, dynamic data) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');

    try {
      _logRequest('PUT', url, body: data);
      final response = await _client.put(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> patch(String endpoint, {dynamic body}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    try {
      _logRequest('PATCH', url, body: body);
      final response = await _client.patch(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');

    try {
      _logRequest('DELETE', url);
      final response = await _client.delete(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  http.Response _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else if (response.statusCode == 401) {
      // Potentially notify AuthProvider to logout
      throw Exception('Unauthorized access. Please login again.');
    } else {
      throw Exception('Server Error (${response.statusCode}): ${response.body}');
    }
  }
}
