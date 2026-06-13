import 'package:equatable/equatable.dart';

class PatientPrescriptionsModel extends Equatable {
  final int id;
  final int patientId;
  final int doctorId;
  final String medicationName;
  final String dosage;
  final String frequency;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String? instructions;
  const PatientPrescriptionsModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.instructions,
  });

  PatientPrescriptionsModel copyWith({
    int? id,
    int? patientId,
    int? doctorId,
    String? medicationName,
    String? dosage,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? instructions,
  }) {
    return PatientPrescriptionsModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      instructions: instructions ?? this.instructions,
    );
  }

  factory PatientPrescriptionsModel.fromJson(Map<String, dynamic> json) {
    return PatientPrescriptionsModel(
      id: json['id'] as int,
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      medicationName: json['medication_name'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      startDate: DateTime.parse(json["start_date"]),
      endDate: DateTime.parse(json["end_date"]),
      status: json['status'] ?? '',
      instructions: json['instructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['patient_id'] = patientId;
    data['doctor_id'] = doctorId;
    data['medication_name'] = medicationName;
    data['dosage'] = dosage;
    data['frequency'] = frequency;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['status'] = status;
    data['instructions'] = instructions;
    return data;
  }

  @override
  List<Object?> get props => [
    id,
    patientId,
    doctorId,
    medicationName,
    dosage,
    frequency,
    startDate,
    endDate,
    status,
    instructions,
  ];
}
