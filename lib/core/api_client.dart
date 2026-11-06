import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// An error returned by the API (or a network failure), with a message that
/// is safe to show to the user.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

typedef TokenReader = String? Function();

/// Thin JSON-over-HTTP client for the SSB Tour API.
class ApiClient {
  ApiClient({required this.baseUrl, required this.readToken, http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final String baseUrl;
  final TokenReader readToken;
  final http.Client _http;

  /// Called whenever the API rejects the stored token, so the app can sign out.
  void Function()? onUnauthorized;

  static const _timeout = Duration(seconds: 15);

  Future<Map<String, dynamic>> get(String path, {Map<String, String?>? query}) => _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(String path, [Object? body]) => _send('POST', path, body: body);

  Future<Map<String, dynamic>> patch(String path, [Object? body]) => _send('PATCH', path, body: body);

  Future<Map<String, dynamic>> _send(String method, String path, {Map<String, String?>? query, Object? body}) async {
    final params = {
      for (final e in (query ?? const <String, String?>{}).entries)
        if (e.value != null && e.value!.isNotEmpty) e.key: e.value!,
    };
    final uri = Uri.parse('$baseUrl/api$path').replace(queryParameters: params.isEmpty ? null : params);
    final token = readToken();
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request).timeout(_timeout));
    } on TimeoutException {
      throw ApiException('The server took too long to respond. Please try again.');
    } catch (_) {
      throw ApiException('Unable to reach the server. Check your connection and that the API is running.');
    }

    final decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    final json = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};

    if (response.statusCode >= 200 && response.statusCode < 300) return json;

    final error = json['error'] as Map<String, dynamic>?;
    final exception = ApiException(
      (error?['message'] as String?) ?? 'Request failed (${response.statusCode})',
      statusCode: response.statusCode,
      code: error?['code'] as String?,
    );
    if (exception.isUnauthorized && token != null) onUnauthorized?.call();
    throw exception;
  }
}
