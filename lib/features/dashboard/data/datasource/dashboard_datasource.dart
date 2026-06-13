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
    final role = SessionService.role ?? 'medecin';
    final today = DateTime.now().toIso8601String().split('T')[0];
    log('[DashboardDatasource] Rôle: $role');

    return switch (role) {
      'admin' || 'staff' => _loadAdminDashboard(),
      _ => _loadDoctorDashboard(today),
    };
  }

  // ── Admin/Staff : stats globales ──────────────────────────────
  Future<DashboardData> _loadAdminDashboard() async {
    final results = await Future.wait([
      _tryGet(ApiEndpoints.adminGetStats),
      _tryGet(
        ApiEndpoints.adminGetAccessLogs,
        queryParams: {'page': '1', 'limit': '5'},
      ),
    ]);

    final stats = results[0];
    final logsData = results[1];
    final totals = stats['totals'] as Map<String, dynamic>? ?? {};
    log('[Admin Data Source] Statistiques: $stats');
    log('[Admin Data Source] logs Data: $logsData');

    final doctorName = SessionService.doctorName ?? 'Administrateur';
    final nameParts = doctorName.trim().split(' ');

    final kpis = [
      KpiItem(
        icon: Icons.groups_rounded,
        label: 'Total patients',
        value: (totals['patients'] as int? ?? 0).toString(),
        tone: AppColors.primary,
      ),
      KpiItem(
        icon: Icons.medical_services_outlined,
        label: 'Médecins actifs',
        value: (totals['doctors'] as int? ?? 0).toString(),
        tone: AppColors.info,
      ),
      KpiItem(
        icon: Icons.calendar_month_rounded,
        label: 'RDV aujourd\'hui',
        value: (totals['rdvToday'] as int? ?? 0).toString(),
        tone: AppColors.primary,
      ),
      KpiItem(
        icon: Icons.mark_email_unread_rounded,
        label: 'Messages ce mois',
        value: (totals['messagesMois'] as int? ?? 0).toString(),
        tone: AppColors.info,
      ),
      KpiItem(
        icon: Icons.history_outlined,
        label: 'Accès dossiers',
        value: (totals['accessLogsMois'] as int? ?? 0).toString(),
        tone: AppColors.warning,
      ),
    ];

    // Activité récente depuis les logs d'accès
    final logsRaw = logsData['logs'] as List? ?? [];
    final activity = logsRaw
        .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return DashboardData(
      doctor: DoctorInfo(
        firstName: nameParts.isNotEmpty ? nameParts.first : 'Admin',
        lastName: nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
        role: 'admin',
      ),
      kpis: kpis,
      criticalAlerts: [],
      rdvDuJour: [], // Admin n'a pas d'agenda personnel
      recentActivity: activity,
    );
  }

  // ── Médecin : ses propres stats + son agenda ───────────────────
  Future<DashboardData> _loadDoctorDashboard(String today) async {
    final results = await Future.wait([
      _tryGet(ApiEndpoints.doctorGetStats),
      _tryGet(
        ApiEndpoints.doctorGetAgenda,
        queryParams: {'dateStart': today, 'dateEnd': today},
      ),
      _tryGet(
        ApiEndpoints.doctorGetAgenda,
        queryParams: {'dateStart': today, 'dateEnd': today, 'mode': 'queue'},
      ),
    ]);

    final stats = results[0];
    final agendaData = results[1];
    final queueData = results[2];

    final totals = stats['totals'] as Map<String, dynamic>? ?? {};
    final alertsRaw = stats['criticalAlerts'] as List? ?? [];
    final agenda = agendaData['agenda'] as List? ?? [];
    final queue = queueData['queue'] as List? ?? [];

    final doctorName = SessionService.doctorName ?? 'Médecin';
    final nameParts = doctorName.trim().split(' ');

    final criticalAlerts = alertsRaw
        .map((e) => AlertItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final rdvList = agenda
        .map((e) => RdvItem.fromJson(e as Map<String, dynamic>))
        .toList();

    // Activité = file d'attente du jour comme activité récente
    final activity = queue
        .map((e) {
          final patient = e['patients'] as Map<String, dynamic>?;
          return ActivityItem(
            time: e['scheduledTime'] as String? ?? '--:--',
            event:
                'RDV — ${patient?['first_name'] ?? ''} ${patient?['last_name'] ?? ''}',
            actor: 'Dr. ${nameParts.first}',
            status: switch (e['status'] as String? ?? 'pending') {
              'confirmed' => 'valide',
              'critical' => 'alerte',
              _ => 'envoye',
            },
          );
        })
        .take(5)
        .toList();

    final kpis = [
      KpiItem(
        icon: Icons.groups_rounded,
        label: 'Patients aujourd\'hui',
        value: (totals['patientsAujourdhui'] as int? ?? 0).toString(),
        tone: AppColors.primary,
      ),
      KpiItem(
        icon: Icons.list_alt_rounded,
        label: 'File clinique',
        value: (totals['fileClinique'] as int? ?? 0).toString(),
        tone: AppColors.warning,
      ),
      KpiItem(
        icon: Icons.calendar_month_rounded,
        label: 'RDV du jour',
        value: (totals['rdvAujourdhui'] as int? ?? rdvList.length).toString(),
        tone: AppColors.info,
      ),
      KpiItem(
        icon: Icons.mark_email_unread_rounded,
        label: 'Messages non lus',
        value: (totals['messagesNonLus'] as int? ?? 0).toString(),
        tone: AppColors.info,
      ),
      KpiItem(
        icon: Icons.warning_rounded,
        label: 'Alertes critiques',
        value: criticalAlerts.length.toString(),
        tone: AppColors.critical,
      ),
    ];

    return DashboardData(
      doctor: DoctorInfo(
        firstName: nameParts.isNotEmpty ? nameParts.first : 'Dr.',
        lastName: nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
        role: 'medecin',
      ),
      kpis: kpis,
      criticalAlerts: criticalAlerts,
      rdvDuJour: rdvList,
      recentActivity: activity,
    );
  }

  // ── Helper : appel sans crash si erreur ───────────────────────
  Future<Map<String, dynamic>> _tryGet(
    String url, {
    Map<String, String>? queryParams,
  }) async {
    try {
      return await ApiClient.get(url, queryParams: queryParams);
    } catch (e) {
      log('[DashboardDatasource] Erreur $url: $e');
      return {};
    }
  }

  // lib/features/dashboard/data/datasource/dashboard_datasource.dart
  // Méthode _loadDoctorDashboard — corriger le parsing

  // Future<DashboardData> _loadDoctorDashboard(String today) async {
  //     final results = await Future.wait([
  //       _tryGet(ApiEndpoints.doctorGetStats),
  //       _tryGet(
  //         ApiEndpoints.doctorGetAgenda,
  //         queryParams: { 'dateStart': today, 'dateEnd': today, 'mode': 'queue' },
  //       ),
  //     ]);

  //     final stats     = results[0];
  //     final queueData = results[1];

  //     // ← Correction : (num?)?.toInt() ?? 0
  //     final totals = stats['totals'] as Map<String, dynamic>? ?? {};
  //     final alertsRaw = stats['criticalAlerts'] as List? ?? [];
  //     final rdvRaw    = stats['rdvToday']       as List? ?? [];
  //     final queue     = queueData['queue']      as List? ?? [];

  //     final criticalAlerts = alertsRaw
  //         .map((e) => AlertItem.fromJson(e as Map<String, dynamic>))
  //         .toList();

  //     final rdvList = rdvRaw
  //         .map((e) => RdvItem.fromJson(e as Map<String, dynamic>))
  //         .toList();

  //     final activity = queue.take(5).map((e) {
  //       final patient = e['patients'] as Map<String, dynamic>?;
  //       return ActivityItem(
  //         time:   (e['scheduledTime'] as String?) ?? '--:--',
  //         event:  'RDV — ${patient?['first_name'] ?? ''} ${patient?['last_name'] ?? ''}'.trim(),
  //         actor:  '',
  //         status: switch (e['status'] as String? ?? 'pending') {
  //           'confirmed' => 'valide',
  //           'critical'  => 'alerte',
  //           _           => 'envoye',
  //         },
  //       );
  //     }).toList();

  //     final doctorName = SessionService.doctorName ?? 'Médecin';
  //     final nameParts  = doctorName.trim().split(' ');

  //     final kpis = [
  //       KpiItem(
  //         icon:  Icons.groups_rounded,
  //         label: "Patients aujourd'hui",
  //         // ← Correction : (num?)?.toInt() ?? 0
  //         value: ((totals['patientsAujourdhui'] as num?)?.toInt() ?? 0).toString(),
  //         tone:  AppColors.primary,
  //       ),
  //       KpiItem(
  //         icon:  Icons.list_alt_rounded,
  //         label: 'File clinique',
  //         value: ((totals['fileClinique'] as num?)?.toInt() ?? 0).toString(),
  //         tone:  AppColors.warning,
  //       ),
  //       KpiItem(
  //         icon:  Icons.calendar_month_rounded,
  //         label: 'RDV du jour',
  //         value: ((totals['rdvAujourdhui'] as num?)?.toInt() ?? rdvList.length).toString(),
  //         tone:  AppColors.info,
  //       ),
  //       KpiItem(
  //         icon:  Icons.mark_email_unread_rounded,
  //         label: 'Messages non lus',
  //         value: ((totals['messagesNonLus'] as num?)?.toInt() ?? 0).toString(),
  //         tone:  AppColors.info,
  //       ),
  //       KpiItem(
  //         icon:  Icons.warning_rounded,
  //         label: 'Alertes critiques',
  //         value: criticalAlerts.length.toString(),
  //         tone:  AppColors.critical,
  //       ),
  //     ];

  //     return DashboardData(
  //       doctor: DoctorInfo(
  //         firstName: nameParts.isNotEmpty ? nameParts.first : 'Dr.',
  //         lastName:  nameParts.length > 1  ? nameParts.skip(1).join(' ') : '',
  //         role:      'medecin',
  //       ),
  //       kpis:           kpis,
  //       criticalAlerts: criticalAlerts,
  //       rdvDuJour:      rdvList,
  //       recentActivity: activity,
  //     );
  //   }
}

// // lib/features/dashboard/data/datasource/dashboard_datasource.dart
// // Remplacer _loadStats() et adapter load()

// import 'dart:developer';
// import 'package:flutter/material.dart';

// import '../../../../core/api/api_client.dart';
// import '../../../../core/api/api_endpoints.dart';
// import '../../../../core/services/session_service.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../models/dashboard_models.dart';

// class DashboardDatasource {
//   const DashboardDatasource();

//   Future<DashboardData> load() async {
//     final today = DateTime.now().toIso8601String().split('T')[0];
//     log('[DashboardDatasource] Chargement — $today');

//     // Charger stats + agenda en parallèle
//     // Les stats viennent de doctor-get-stats (médecin voit seulement ses données)
//     final results = await Future.wait([
//       _loadDoctorStats(),    // index 0
//       _loadAgenda(today),    // index 1
//       _loadActivity(),       // index 2
//     ]);

//     final stats    = results[0] as Map<String, dynamic>;
//     log('[DashboardDatasource] Stats chargées: $stats');
//     final agenda   = results[1] as List<dynamic>;
//     final activity = results[2] as List<dynamic>;

//     // ── DoctorInfo depuis SessionService ────────────────────────
//     final fullName  = SessionService.doctorName ?? 'Médecin';
//     final nameParts = fullName.trim().split(' ');

//     final doctor = DoctorInfo(
//       firstName: nameParts.isNotEmpty ? nameParts.first : 'Dr.',
//       lastName:  nameParts.length > 1  ? nameParts.skip(1).join(' ') : '',
//       role:      SessionService.role ?? 'medecin',
//     );

//     // ── Totals depuis doctor-get-stats ───────────────────────────
//     final totals = stats['totals'] as Map<String, dynamic>? ?? {};

//     // ── Alertes critiques depuis les stats du médecin ────────────
//     final alertsRaw = stats['criticalAlerts'] as List<dynamic>? ?? [];
//     log('[DashboardDatasource] Alertes brutes: ${alertsRaw.length}');
//     final criticalAlerts = alertsRaw
//         .map((e) => AlertItem.fromJson(e as Map<String, dynamic>))
//         .toList();
//     log('[DashboardDatasource] Alertes critiques: ${criticalAlerts.length}');

//     // ── RDV du jour depuis l'agenda ──────────────────────────────
//     final rdvList = agenda
//         .map((e) => RdvItem.fromJson(e as Map<String, dynamic>))
//         .toList();

//     // ── Activité récente ─────────────────────────────────────────
//     final activityList = activity
//         .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
//         .toList();

//     // ── KPI items avec icônes — reprend la structure mock existante
//     final kpis = [
//       KpiItem(
//         icon:  Icons.groups_rounded,
//         label: 'Patients aujourd\'hui',
//         value: (totals['patientsAujourdhui'] as int? ?? 0).toString(),
//         tone:  AppColors.primary,
//       ),
//       KpiItem(
//         icon:  Icons.list_alt_rounded,
//         label: 'File clinique',
//         value: (totals['fileClinique'] as int? ?? 0).toString(),
//         tone:  AppColors.warning,
//       ),
//       KpiItem(
//         icon:  Icons.calendar_month_rounded,
//         label: 'Rendez-vous du jour',
//         value: (totals['rdvAujourdhui'] as int? ?? rdvList.length).toString(),
//         tone:  AppColors.info,
//       ),
//       KpiItem(
//         icon:  Icons.mark_email_unread_rounded,
//         label: 'Messages à traiter',
//         value: (totals['messagesNonLus'] as int? ?? 0).toString(),
//         tone:  AppColors.info,
//       ),
//       KpiItem(
//         icon:  Icons.warning_rounded,
//         label: 'Alertes critiques',
//         value: criticalAlerts.length.toString(),
//         tone:  AppColors.critical,
//       ),
//     ];

//     return DashboardData(
//       doctor:         doctor,
//       kpis:           kpis,
//       criticalAlerts: criticalAlerts,
//       rdvDuJour:      rdvList,
//       recentActivity: activityList,
//     );
//   }

//   // ── doctor-get-stats (médecin voit seulement ses données) ──────
//   Future<Map<String, dynamic>> _loadDoctorStats() async {
//     try {
//       return await ApiClient.get(ApiEndpoints.doctorGetStats);
//     } catch (e) {
//       log('[DashboardDatasource] Stats médecin erreur: $e');
//       return {'totals': {}, 'criticalAlerts': []};
//     }
//   }

//   // ── Agenda du jour ─────────────────────────────────────────────
//   Future<List<dynamic>> _loadAgenda(String today) async {
//     try {
//       final data = await ApiClient.get(
//         ApiEndpoints.doctorGetAgenda,
//         queryParams: { 'dateStart': today, 'dateEnd': today },
//       );
//       return data['agenda'] as List? ?? [];
//     } catch (e) {
//       log('[DashboardDatasource] Agenda erreur: $e');
//       return [];
//     }
//   }

//   // ── Activité récente (logs d'accès dossiers) ───────────────────
//   Future<List<dynamic>> _loadActivity() async {
//     try {
//       // Pour l'instant retourner vide
//       // sera remplacé quand doctor-get-activity-logs sera créé
//       return [];
//     } catch (e) {
//       log('[DashboardDatasource] Activity erreur: $e');
//       return [];
//     }
//   }
// }
