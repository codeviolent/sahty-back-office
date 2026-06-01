import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_endpoints.dart';
import 'api_error.dart';
import '../services/session_service.dart';

class ApiClient {
  ApiClient._();

  static final _client = http.Client();

  // ── GET ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? queryParams,
    bool requireAuth = true,
  }) async {
    final uri = queryParams != null
        ? Uri.parse(url).replace(queryParameters: queryParams)
        : Uri.parse(url);

    final response = await _client
        .get(uri, headers: _headers(requireAuth))
        .timeout(const Duration(seconds: 15));

    return _parse(response);
  }

  // ── POST ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) async {
    final response = await _client
        .post(
          Uri.parse(url),
          headers: _headers(requireAuth),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    return _parse(response);
  }

  // ── POST Auth (format form-urlencoded) ────────────────────────
  static Future<Map<String, dynamic>> postAuth(
    String url,
    Map<String, dynamic> body,
  ) async {
    final response = await _client
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'apikey': ApiEndpoints.anonKey,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw ApiError.fromStatusCode(
      response.statusCode,
      decoded['error_description'] ??
          decoded['msg'] ??
          'Erreur d\'authentification',
    );
  }

  // ── Headers ───────────────────────────────────────────────────
  static Map<String, String> _headers(bool requireAuth) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'apikey': ApiEndpoints.anonKey,
    };

    if (requireAuth) {
      final jwt = SessionService.jwt;
      if (jwt != null) {
        headers['Authorization'] = 'Bearer $jwt';
      }
    }

    return headers;
  }

  // ── Parser réponse ────────────────────────────────────────────
  static Map<String, dynamic> _parse(http.Response response) {
    late Map<String, dynamic> body;

    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiError(
        message: 'Réponse invalide du serveur',
        statusCode: response.statusCode,
        type: ApiErrorType.serverError,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body['success'] == true) {
        return body['data'] as Map<String, dynamic>? ?? body;
      }
      throw ApiError.fromStatusCode(
        response.statusCode,
        body['error'] as String? ?? 'Erreur inconnue',
      );
    }

    throw ApiError.fromStatusCode(
      response.statusCode,
      body['error'] as String? ??
          body['message'] as String? ??
          'Erreur ${response.statusCode}',
    );
  }

  static Future<Map<String, dynamic>> getWithJwt(
    String url, {
    required String jwt,
    Map<String, String>? queryParams,
  }) async {
    final uri = queryParams != null
        ? Uri.parse(url).replace(queryParameters: queryParams)
        : Uri.parse(url);

    final response = await _client
        .get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'apikey': ApiEndpoints.anonKey,
            'Authorization': 'Bearer $jwt',
          },
        )
        .timeout(const Duration(seconds: 15));

    return _parse(response);
  }
}
