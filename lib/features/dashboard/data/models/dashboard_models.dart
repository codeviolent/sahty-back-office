import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:sahty_back_office/core/widgets/alert_stack.dart';

class DashboardData extends Equatable {
  final DoctorInfo         doctor;
  final List<KpiItem>      kpis;
  final List<AlertItem>    criticalAlerts;
  final List<RdvItem>      rdvDuJour;
  final List<ActivityItem> recentActivity;

  const DashboardData({
    required this.doctor,
    required this.kpis,
    required this.criticalAlerts,
    required this.rdvDuJour,
    required this.recentActivity,
  });
  @override
  List<Object?> get props => [doctor, kpis, criticalAlerts, rdvDuJour, recentActivity];
}
class DoctorInfo extends Equatable{
  final String firstName;
  final String lastName;
  final String role;

  const DoctorInfo({
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  String get displayName => '$firstName $lastName';
  String get greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }
  @override
  List<Object?> get props => [firstName, lastName, role];
}

class KpiItem {
  final IconData icon;
  final String   label;
  final String   value;   // String pour garder compatibilité avec l'UI existante
  final Color    tone;

  const KpiItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });
}

enum KpiType { patients, file, rdv, messages, alertes }

class AlertItem {
  final String patientName;
  final String message;
  final String level; // 'critique' | 'high' | 'medium'

  const AlertItem({
    required this.patientName,
    required this.message,
    required this.level,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      patientName: json['patientName'] as String? ?? '',
      message:     json['message']     as String? ?? '',
      level:       json['level']       as String? ?? 'medium',
    );
  }

  // ← Conversion vers AlertData (utilisé par AlertStack)
  AlertData toAlertData() {
    return AlertData(
      title:      _buildTitle(),
      message:    '$patientName — $message',
      isCritical: level == 'critique',
    );
  }

  String _buildTitle() {
    return switch (level) {
      'critique' => 'Résultat critique',
      'high'     => 'Alerte haute priorité',
      _          => 'Alerte médicale',
    };
  }
}
class RdvItem {
  final int    id;
  final String time;
  final String patientName;
  final String motif;
  final String status;

  const RdvItem({
    required this.id,
    required this.time,
    required this.patientName,
    required this.motif,
    required this.status,
  });

  factory RdvItem.fromJson(Map<String, dynamic> json) {
    final patient = json['patients'] as Map<String, dynamic>?;
    final time    = (json['start_time'] as String? ?? '00:00:00')
        .substring(0, 5);

    return RdvItem(
      id:          json['id'] as int? ?? 0,
      time:        time,
      patientName: patient != null
          ? '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}'.trim()
          : 'Patient inconnu',
      motif:       json['reason'] as String? ?? '',
      status:      json['status'] as String? ?? 'pending',
    );
  }

  // Convertir le status API vers _RecordStatus pour l'UI existante
  String get statusLabel {
    return switch (status) {
      'confirmed'  => 'Confirmé',
      'completed'  => 'Consulté',
      'cancelled'  => 'Annulé',
      'no_show'    => 'Absent',
      'critical'   => 'Critique',
      'teleconsult' => 'En ligne',
      _            => 'En attente',
    };
  }

  bool get isCritique => status == 'critical';
  bool get isEnLigne  => status == 'teleconsult';
}

class ActivityItem {
  final String time;
  final String event;
  final String actor;
  final String status; // valide | alerte | bloque | envoye | lecture

  const ActivityItem({
    required this.time,
    required this.event,
    required this.actor,
    required this.status,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    final doctor  = json['doctors']  as Map<String, dynamic>?;
    final patient = json['patients'] as Map<String, dynamic>?;

    final actorName = doctor != null
        ? 'Dr. ${doctor['last_name'] ?? ''}'
        : 'Système';

    final patientName = patient != null
        ? '${patient['first_name']} ${patient['last_name']}'
        : '';

    final sessionStart = DateTime.tryParse(
      json['session_start'] as String? ?? '');
    final timeStr = sessionStart != null
        ? '${sessionStart.hour.toString().padLeft(2,'0')}:'
          '${sessionStart.minute.toString().padLeft(2,'0')}'
        : '--:--';

    return ActivityItem(
      time:   timeStr,
      event:  'Dossier consulté — $patientName',
      actor:  actorName,
      status: 'lecture',
    );
  }
  List<Object?> get props => [time, event, actor, status];
}