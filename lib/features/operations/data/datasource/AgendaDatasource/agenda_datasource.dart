import 'dart:developer';

import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../models/appointment_item.dart';


class AgendaDatasource {
  const AgendaDatasource();

  Future<ListRdv> load() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    log('[AgendaDatasource] Chargement — $today');

    // Charger stats + agenda en parallèle
    // Les stats viennent de doctor-get-stats (médecin voit seulement ses données)
    final results = await Future.wait([
      _loadAgenda(today),    // index 1
    ]);
    final agenda   = results[0];
    // ── RDV du jour depuis l'agenda ──────────────────────────────
    final rdvList = agenda
        .map((e) => AppointmentItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return ListRdv(
      rdvList:      rdvList,
    );
  }
  // ── Agenda du jour ─────────────────────────────────────────────
  Future<List<dynamic>> _loadAgenda(String today) async {
    try {
      final data = await ApiClient.get(
        ApiEndpoints.doctorGetAgenda,
        queryParams: { 'dateStart': today, 'dateEnd': today },
      );
      return data['agenda'] as List? ?? [];
    } catch (e) {
      log('[AgendaDatasource] Agenda erreur: $e');
      return [];
    }
  }
}