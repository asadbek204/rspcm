import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_endpoints.dart';

class ApiClient {
  final http.Client _client = http.Client();

  void _logRequest(String method, Uri url, {dynamic body}) {
    // Keep request logging centralized so every API call is traceable.
    print('→ $method $url');
    if (body != null) {
      final encodedBody = body is String ? body : jsonEncode(body);
      print('  BODY: $encodedBody');
    }
  }

  void _logResponse(http.Response response, Duration elapsed) {
    final ms = elapsed.inMilliseconds;
    print('← ${response.statusCode} (${ms}ms) ${response.request?.url}');
    if (response.body.isNotEmpty) {
      // Truncate very long bodies so the log stays readable.
      final body = response.body.length > 500
          ? '${response.body.substring(0, 500)}…'
          : response.body;
      print('  RESPONSE: $body');
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
      final sw = Stopwatch()..start();
      final response = await _client.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response, sw.elapsed);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');

    try {
      _logRequest('GET', url);
      final sw = Stopwatch()..start();
      final response = await _client.get(url, headers: headers);
      return _handleResponse(response, sw.elapsed);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> put(String endpoint, dynamic data) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');

    try {
      _logRequest('PUT', url, body: data);
      final sw = Stopwatch()..start();
      final response = await _client.put(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response, sw.elapsed);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> patch(String endpoint, {dynamic body}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    try {
      _logRequest('PATCH', url, body: body);
      final sw = Stopwatch()..start();
      final response = await _client.patch(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response, sw.elapsed);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');

    try {
      _logRequest('DELETE', url);
      final sw = Stopwatch()..start();
      final response = await _client.delete(url, headers: headers);
      return _handleResponse(response, sw.elapsed);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  http.Response _handleResponse(http.Response response, Duration elapsed) {
    _logResponse(response, elapsed);
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
