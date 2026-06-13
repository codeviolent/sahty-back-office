import 'dart:developer';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/dossier_models.dart';

class DossierDatasource {
  const DossierDatasource();

  // ── Vérification QR + PIN ──────────────────────────────────────
  Future<PatientSession> verifyAccess({
    required String qrToken,
    required String pin,
  }) async {
    log('[DossierDatasource] Vérification: QR=${qrToken.substring(0, 8)}...');
    final data = await ApiClient.post(ApiEndpoints.doctorVerifyPatientAccess, {
      'qrToken': qrToken,
      'pin': pin,
    });
    try {
      final session = PatientSession.fromJson(data);
      log('''
      [PatientSession créée]
        sessionId    : ${session.sessionId}
        patientId    : ${session.patientId}
        displayName  : ${session.displayName}
        bloodType    : ${session.bloodType}
        expiresAt    : ${session.expiresAt}
        remaining    : ${session.remaining.inMinutes}min
        allergies    : ${session.criticalAllergies}
        prescriptions: ${session.activePrescriptions}
      ''');
      return session;
    } catch (e) {
      log(
        '[DossierDatasource] ERREUR: data[\'data\'] invalide ou manquante: $e, data: $data',
      );
      throw Exception('Données de session invalides');
    }
    // final overviewRaw = data['data'] as Map<String, dynamic>;
    // final session = PatientSession.fromJson(overviewRaw);
    // log('''
    // [PatientSession créée]
    //   sessionId    : ${session.sessionId}
    //   patientId    : ${session.patientId}
    //   displayName  : ${session.displayName}
    //   bloodType    : ${session.bloodType}
    //   expiresAt    : ${session.expiresAt}
    //   remaining    : ${session.remaining.inMinutes}min
    //   allergies    : ${session.criticalAllergies.map((a) => '${a.allergen}(${a.severity})').join(', ')}
    //   prescriptions: ${session.activePrescriptions.map((p) => p.medicationName).join(', ')}
    // ''');
  }

  // ── Charger une section (retourne toujours List) ───────────────
  // SAUF overview qui utilise loadOverview()
  Future<List<dynamic>> loadSection({
    required int patientId,
    required String sessionId,
    required String sectionKey,
  }) async {
    log('[DossierDatasource] Section: $sectionKey pour patient $patientId');

    final data = await ApiClient.get(
      ApiEndpoints.doctorGetPatientDossier,
      queryParams: {
        'patientId': patientId.toString(),
        'sessionId': sessionId,
        'section': sectionKey,
      },
    );

    // data['data'] peut être une List ou un Map (pour overview)
    // On ne traite ici que les sections qui retournent une List
    final raw = data['data'];

    if (raw is List) {
      log('[DossierDatasource] Données reçues: ${raw.length} éléments');
      log("[DossierDatasource] Données: $raw");
      return raw;
    }

    // Si Map (ne devrait pas arriver ici — overview utilise loadOverview)
    if (raw is Map) {
      log(
        '[DossierDatasource] AVERTISSEMENT: Map reçu pour section $sectionKey',
      );
      return [];
    }

    return [];
  }

  Future<Map<String, dynamic>> loadOverviewRaw({
    required int patientId,
    required String sessionId,
  }) async {
    log('[DossierDatasource] Overview RAW → patient $patientId');

    final response = await ApiClient.get(
      ApiEndpoints.doctorGetPatientDossier,
      queryParams: {
        'patientId': patientId.toString(),
        'sessionId': sessionId,
        'section': 'overview',
      },
    );

    final raw = response['data'];
    if (raw == null) throw Exception('Overview: data est null');

    final overviewMap = raw as Map<String, dynamic>;
    log('[DossierDatasource] Overview keys: ${overviewMap.keys.toList()}');
    log('[DossierDatasource] Overview: $overviewMap');
    return overviewMap;
  }

  // ── Charger l'overview (retourne PatientOverviewData) ─────────
  Future<PatientOverviewData> loadOverview({
    required int patientId,
    required String sessionId,
  }) async {
    log('[DossierDatasource] Chargement overview patient $patientId...');

    final data = await ApiClient.get(
      ApiEndpoints.doctorGetPatientDossier,
      queryParams: {
        'patientId': patientId.toString(),
        'sessionId': sessionId,
        'section': 'overview',
      },
    );

    // Récupérer l'objet overview dans data['data']
    final raw = data['data'];
    log('[DossierDatasource] Données overview reçues: ${raw.runtimeType}');
    log('[DossierDatasource] Données overview brutes: $raw');
    log("Session ID: $sessionId, Patient ID: $patientId");
    if (raw == null) {
      log('[DossierDatasource] ERREUR: data[\'data\'] est null');
      throw Exception('Données overview manquantes');
    }

    final overviewRaw = raw as Map<String, dynamic>;
    log('[DossierDatasource] Overview keys: ${overviewRaw.keys.toList()}');
    return PatientOverviewData.fromJson(overviewRaw);
  }
}
