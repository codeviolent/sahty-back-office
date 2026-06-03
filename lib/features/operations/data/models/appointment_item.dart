import 'package:equatable/equatable.dart';

class AppointmentItem extends Equatable {
  final int    id;
  final String time;
  final String patientName;
  final String motif;
  final String status;

  const AppointmentItem({
    required this.id,
    required this.time,
    required this.patientName,
    required this.motif,
    required this.status,
  });

  factory AppointmentItem.fromJson(Map<String, dynamic> json) {
    final patient = json['patients'] as Map<String, dynamic>?;
    final time    = (json['start_time'] as String? ?? '00:00:00')
        .substring(0, 5);

    return AppointmentItem(
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

  @override
  List<Object?> get props => [id, time, patientName, motif, status];
}

class ListRdv extends Equatable {
  final List<AppointmentItem> rdvList;

  const ListRdv({required this.rdvList});

  @override
  List<Object?> get props => [rdvList];
}
