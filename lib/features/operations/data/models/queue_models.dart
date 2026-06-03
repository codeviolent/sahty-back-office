import 'package:equatable/equatable.dart';

class QueueItem extends Equatable {
  final int id;
  final String patientName;
  final String patientPhone;
  final String reason;
  final String status;
  final String scheduledTime;
  final String appointmentDate;
  final int waitMinutes;
  final String priority;
  final bool hasStarted;

  const QueueItem({
    required this.id,
    required this.patientName,
    required this.patientPhone,
    required this.reason,
    required this.status,
    required this.scheduledTime,
    required this.appointmentDate,
    required this.waitMinutes,
    required this.priority,
    required this.hasStarted,
  });

  factory QueueItem.fromJson(Map<String, dynamic> json) {
    final patient = json['patients'] as Map<String, dynamic>?;
    return QueueItem(
      id: json['id'] as int,
      patientName: patient != null
          ? '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}'
                .trim()
          : 'Patient',
      patientPhone: patient?['phone'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      scheduledTime: json['scheduledTime'] as String? ?? '--:--',
      appointmentDate: json['appointment_date'] as String? ?? '',
      waitMinutes: json['waitMinutes'] as int? ?? 0,
      priority: json['priority'] as String? ?? 'low',
      hasStarted: json['hasStarted'] as bool? ?? false,
    );
  }

  // ── Recalcul local depuis l'heure prévue ──────────────────────
  // Utilisé par le ticker Flutter (toutes les 60s) sans appel API
  int get currentWaitMinutes {
    try {
      final now = DateTime.now();
      final timeParts = scheduledTime.split(':');
      final scheduled = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(timeParts[0]), // heure
        int.parse(timeParts[1]), // minutes
      );
      final diff = now.difference(scheduled).inMinutes;
      return diff < 0 ? 0 : diff; // pas encore commencé → 0
    } catch (_) {
      return waitMinutes; // fallback sur la valeur API
    }
  }

  QueuePriority get currentPriority {
    final min = currentWaitMinutes;
    if (min > 30) return QueuePriority.high;
    if (min > 15) return QueuePriority.medium;
    return QueuePriority.low;
  }

  String get waitLabel {
    final min = currentWaitMinutes;
    if (min == 0) return 'À l\'heure';
    if (min < 60) return '${min} min';
    final h = min ~/ 60;
    final m = min % 60;
    return m > 0 ? '${h}h ${m}min' : '${h}h';
  }

  @override
  List<Object?> get props => [
    id,
    patientName,
    patientPhone,
    reason,
    status,
    scheduledTime,
    appointmentDate,
    waitMinutes,
    priority,
    hasStarted,
  ];
}

enum QueuePriority { high, medium, low }
