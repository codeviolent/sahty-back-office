import 'dart:async';
/// Service centralisé pour la session utilisateur.
/// Stocké en mémoire — pas de dépendance externe.
class SessionService {
  SessionService._();

  // ── JWT ───────────────────────────────────────────────────────
  static String?  _jwt;
  static String?  get jwt => _jwt;

  // ── Identité ──────────────────────────────────────────────────
  static String?  _userId;
  static String?  get userId => _userId;

  static String?  _role;
  static String?  get role => _role;

  static String?  _doctorName;
  static String?  get doctorName => _doctorName;

  static int?     _doctorId;
  static int?     get doctorId => _doctorId;

  // ── Session patient (consultation active) ─────────────────────
  static String?   _patientSessionId;
  static int?      _patientSessionPatientId;
  static DateTime? _patientSessionExpiry;
  static Timer?    _patientSessionTimer;

  // Callback quand la session expire
  static VoidCallback? onPatientSessionExpired;

  // ── Setters ───────────────────────────────────────────────────
  static void setAuth({
    required String jwt,
    required String userId,
    required String role,
    String? doctorName,
    int?    doctorId,
  }) {
    _jwt        = jwt;
    _userId     = userId;
    _role       = role;
    _doctorName = doctorName;
    _doctorId   = doctorId;
  }

  static void setPatientSession({
    required String   sessionId,
    required int      patientId,
    required DateTime expiresAt,
  }) {
    _patientSessionId        = sessionId;
    _patientSessionPatientId = patientId;
    _patientSessionExpiry    = expiresAt;

    // Annuler le timer précédent
    _patientSessionTimer?.cancel();

    // Déclencher le callback à l'expiration
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) {
      _clearPatientSession();
      return;
    }

    _patientSessionTimer = Timer(remaining, () {
      _clearPatientSession();
      onPatientSessionExpired?.call();
    });
  }

  // ── Getters session patient ───────────────────────────────────
  static String?   get patientSessionId        => _patientSessionId;
  static int?      get patientSessionPatientId => _patientSessionPatientId;
  static DateTime? get patientSessionExpiry    => _patientSessionExpiry;

  static bool get hasActivePatientSession {
    if (_patientSessionId == null || _patientSessionExpiry == null) return false;
    return _patientSessionExpiry!.isAfter(DateTime.now());
  }

  static Duration get patientSessionRemaining {
    if (_patientSessionExpiry == null) return Duration.zero;
    final remaining = _patientSessionExpiry!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // ── Helpers rôle ──────────────────────────────────────────────
  static bool get isMedecin    => _role == 'medecin';
  static bool get isAdmin      => _role == 'admin';
  static bool get isStaff      => _role == 'staff';
  static bool get isPharma     => _role == 'pharmacien';
  static bool get isAuthenticated => _jwt != null;

  // ── Clear ─────────────────────────────────────────────────────
  static void clear() {
    _jwt        = null;
    _userId     = null;
    _role       = null;
    _doctorName = null;
    _doctorId   = null;
    _clearPatientSession();
  }

  static void _clearPatientSession() {
    _patientSessionTimer?.cancel();
    _patientSessionId        = null;
    _patientSessionPatientId = null;
    _patientSessionExpiry    = null;
  }
}

// Alias pour les callbacks
typedef VoidCallback = void Function();