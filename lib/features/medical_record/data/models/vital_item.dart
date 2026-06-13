import 'package:equatable/equatable.dart';

class PatientVitalsModel extends Equatable {
  final int id;
  final int patientId;
  final String vitalType;
  final num value;
  final String unit;
  final DateTime recordedAt;

  const PatientVitalsModel({
    required this.id,
    required this.patientId,
    required this.vitalType,
    required this.value,
    required this.unit,
    required this.recordedAt,
  });

  factory PatientVitalsModel.fromJson(Map<String, dynamic> json) {
    return PatientVitalsModel(
      id: json['id'],
      patientId: json['patient_id'],
      vitalType: json['vital_type'],
      value: json['value'],
      unit: json['unit'],
      recordedAt: DateTime.parse(json['recorded_at'].toString()),
    );
  }

  @override
  List<Object?> get props => [patientId, vitalType, value, unit, recordedAt];
}
