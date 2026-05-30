// lib/core/api/api_error.dart

class ApiError implements Exception {
  final String  message;
  final int     statusCode;
  final ApiErrorType type;

  const ApiError({
    required this.message,
    required this.statusCode,
    required this.type,
  });

  factory ApiError.fromStatusCode(int code, String message) {
    return ApiError(
      message:    message,
      statusCode: code,
      type:       ApiErrorType.fromCode(code),
    );
  }

  @override
  String toString() => 'ApiError($statusCode): $message';
}

enum ApiErrorType {
  unauthorized,    // 401 — JWT expiré ou invalide
  forbidden,       // 403 — Pas le droit
  notFound,        // 404 — Ressource introuvable
  conflict,        // 409 — Doublon ou conflit
  rateLimited,     // 429 — Brute force ou rate limit
  serverError,     // 500 — Erreur serveur
  networkError,    // Pas de réseau
  unknown;

  static ApiErrorType fromCode(int code) {
    return switch (code) {
      401 => unauthorized,
      403 => forbidden,
      404 => notFound,
      409 => conflict,
      429 => rateLimited,
      500 => serverError,
      _   => unknown,
    };
  }
}