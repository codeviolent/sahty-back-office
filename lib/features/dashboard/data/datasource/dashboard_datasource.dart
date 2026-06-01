// lib/features/dashboard/data/datasource/dashboard_datasource.dart
// Remplacer _loadStats() et adapter load()

import 'dart:developer';
import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/dashboard_models.dart';

class DashboardDatasource {
  const DashboardDatasource();

  Future<DashboardData> load() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    log('[DashboardDatasource] Chargement — $today');

    // Charger stats + agenda en parallèle
    // Les stats viennent de doctor-get-stats (médecin voit seulement ses données)
    final results = await Future.wait([
      _loadDoctorStats(),    // index 0
      _loadAgenda(today),    // index 1
      _loadActivity(),       // index 2
    ]);

    final stats    = results[0] as Map<String, dynamic>;
    final agenda   = results[1] as List<dynamic>;
    final activity = results[2] as List<dynamic>;

    // ── DoctorInfo depuis SessionService ────────────────────────
    final fullName  = SessionService.doctorName ?? 'Médecin';
    final nameParts = fullName.trim().split(' ');

    final doctor = DoctorInfo(
      firstName: nameParts.isNotEmpty ? nameParts.first : 'Dr.',
      lastName:  nameParts.length > 1  ? nameParts.skip(1).join(' ') : '',
      role:      SessionService.role ?? 'medecin',
    );

    // ── Totals depuis doctor-get-stats ───────────────────────────
    final totals = stats['totals'] as Map<String, dynamic>? ?? {};

    // ── Alertes critiques depuis les stats du médecin ────────────
    final alertsRaw = stats['criticalAlerts'] as List<dynamic>? ?? [];
    final criticalAlerts = alertsRaw
        .map((e) => AlertItem.fromJson(e as Map<String, dynamic>))
        .toList();

    // ── RDV du jour depuis l'agenda ──────────────────────────────
    final rdvList = agenda
        .map((e) => RdvItem.fromJson(e as Map<String, dynamic>))
        .toList();

    // ── Activité récente ─────────────────────────────────────────
    final activityList = activity
        .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
        .toList();

    // ── KPI items avec icônes — reprend la structure mock existante
    final kpis = [
      KpiItem(
        icon:  Icons.groups_rounded,
        label: 'Patients aujourd\'hui',
        value: (totals['patientsAujourdhui'] as int? ?? 0).toString(),
        tone:  AppColors.primary,
      ),
      KpiItem(
        icon:  Icons.list_alt_rounded,
        label: 'File clinique',
        value: (totals['fileClinique'] as int? ?? 0).toString(),
        tone:  AppColors.warning,
      ),
      KpiItem(
        icon:  Icons.calendar_month_rounded,
        label: 'Rendez-vous du jour',
        value: (totals['rdvAujourdhui'] as int? ?? rdvList.length).toString(),
        tone:  AppColors.info,
      ),
      KpiItem(
        icon:  Icons.mark_email_unread_rounded,
        label: 'Messages à traiter',
        value: (totals['messagesNonLus'] as int? ?? 0).toString(),
        tone:  AppColors.info,
      ),
      KpiItem(
        icon:  Icons.warning_rounded,
        label: 'Alertes critiques',
        value: criticalAlerts.length.toString(),
        tone:  AppColors.critical,
      ),
    ];

    return DashboardData(
      doctor:         doctor,
      kpis:           kpis,
      criticalAlerts: criticalAlerts,
      rdvDuJour:      rdvList,
      recentActivity: activityList,
    );
  }

  // ── doctor-get-stats (médecin voit seulement ses données) ──────
  Future<Map<String, dynamic>> _loadDoctorStats() async {
    try {
      return await ApiClient.get(ApiEndpoints.doctorGetStats);
    } catch (e) {
      log('[DashboardDatasource] Stats médecin erreur: $e');
      return {'totals': {}, 'criticalAlerts': []};
    }
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
      log('[DashboardDatasource] Agenda erreur: $e');
      return [];
    }
  }

  // ── Activité récente (logs d'accès dossiers) ───────────────────
  Future<List<dynamic>> _loadActivity() async {
    try {
      // Pour l'instant retourner vide
      // sera remplacé quand doctor-get-activity-logs sera créé
      return [];
    } catch (e) {
      log('[DashboardDatasource] Activity erreur: $e');
      return [];
    }
  }
}