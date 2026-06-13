import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';

// ── PatientSession ─────────────────────────────────────────────────
class PatientSession {
  final String sessionId;
  final int patientId;
  final String firstName;
  final String lastName;
  final String bloodType;
  final DateTime expiresAt;
  final DateTime openedAt;
  final List<CriticalAllergyInfo> criticalAllergies;
  final List<PrescriptionItem> activePrescriptions;

  const PatientSession({
    required this.sessionId,
    required this.patientId,
    required this.firstName,
    required this.lastName,
    required this.bloodType,
    required this.expiresAt,
    required this.openedAt,
    required this.criticalAllergies,
    required this.activePrescriptions,
  });

  String get displayName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  Duration get remaining {
    final r = expiresAt.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isWarning => remaining.inMinutes < 5 && !isExpired;

  String get remainingLabel {
    if (isExpired) return 'Expirée';
    final m = remaining.inMinutes;
    final s = remaining.inSeconds % 60;
    if (m > 0) return '${m}min ${s.toString().padLeft(2, '0')}s';
    return '${remaining.inSeconds}s';
  }

  String get durationLabel {
    final elapsed = DateTime.now().difference(openedAt);
    final m = elapsed.inMinutes;
    if (m < 1) return "Ouvert à l'instant";
    return 'Ouvert depuis ${m}min';
  }

  factory PatientSession.fromJson(Map<String, dynamic> json) {
    final patient = json['patient'] as Map<String, dynamic>? ?? {};
    final allergies = json['criticalAllergies'] as List? ?? [];
    final prescriptions = json['activePrescriptions'] as List? ?? [];
    return PatientSession(
      sessionId: json['sessionId']?.toString() ?? '',
      // ← Correction : (num?)?.toInt() pour éviter 'Null is not int'
      patientId: (patient['id'] as num?)?.toInt() ?? 0,
      firstName: patient['firstName'] as String? ?? '',
      lastName: patient['lastName'] as String? ?? '',
      bloodType: patient['bloodType'] as String? ?? 'Inconnu',
      expiresAt: DateTime.parse(
        json['expiresAt'] as String? ??
            DateTime.now().add(const Duration(minutes: 30)).toIso8601String(),
      ),
      openedAt: DateTime.now(),
      criticalAllergies: allergies
          .map((e) => CriticalAllergyInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      activePrescriptions: prescriptions
          .map((e) => PrescriptionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CriticalAllergyInfo {
  final String allergen;
  final String severity;
  const CriticalAllergyInfo({required this.allergen, required this.severity});
  factory CriticalAllergyInfo.fromJson(Map<String, dynamic> j) =>
      CriticalAllergyInfo(
        allergen: j['allergen'] as String? ?? '',
        severity: j['severity'] as String? ?? 'high',
      );
}

// ── DossierSection ─────────────────────────────────────────────────
enum DossierSection {
  overview,
  allergies,
  prescriptions,
  vitals,
  vaccinations,
  medicalRecords,
  labs, // ← NOUVEAU
  imaging, // ← NOUVEAU
  timeline; // ← NOUVEAU

  String get label => switch (this) {
    DossierSection.overview => 'Résumé',
    DossierSection.allergies => 'Allergies',
    DossierSection.prescriptions => 'Ordonnances',
    DossierSection.vitals => 'Constantes',
    DossierSection.vaccinations => 'Vaccins',
    DossierSection.medicalRecords => 'Dossiers',
    DossierSection.labs => 'Analyses',
    DossierSection.imaging => 'Imagerie',
    DossierSection.timeline => 'Chronologie',
  };

  String get apiKey => switch (this) {
    DossierSection.overview => 'overview',
    DossierSection.allergies => 'allergies',
    DossierSection.prescriptions => 'prescriptions',
    DossierSection.vitals => 'vitals',
    DossierSection.vaccinations => 'vaccinations',
    DossierSection.medicalRecords => 'medical_records',
    DossierSection.labs => 'labs',
    DossierSection.imaging => 'imaging',
    DossierSection.timeline => 'timeline',
  };

  IconData get icon => switch (this) {
    DossierSection.overview => Icons.dashboard_outlined,
    DossierSection.allergies => Icons.warning_amber_outlined,
    DossierSection.prescriptions => Icons.medication_outlined,
    DossierSection.vitals => Icons.monitor_heart_outlined,
    DossierSection.vaccinations => Icons.vaccines_outlined,
    DossierSection.medicalRecords => Icons.folder_shared_outlined,
    DossierSection.labs => Icons.science_outlined,
    DossierSection.imaging => Icons.image_search_outlined,
    DossierSection.timeline => Icons.timeline_rounded,
  };
}

// ── TimelineEvent ──────────────────────────────────────────────────
class TimelineEvent {
  final String id;
  final String type;
  final String title;
  final String notes;
  final String date;
  final String? actor;
  final String? status;

  const TimelineEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.notes,
    required this.date,
    this.actor,
    this.status,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> j) => TimelineEvent(
    id: j['id']?.toString() ?? '',
    type: j['type'] as String? ?? 'record',
    title: j['title'] as String? ?? 'Événement',
    notes: j['notes'] as String? ?? '',
    date: j['date'] as String? ?? '',
    actor: j['actor'] as String?,
    status: j['status'] as String?,
  );

  String get formattedDate {
    try {
      final dt = DateTime.parse(date);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return date;
    }
  }

  IconData get icon => switch (type) {
    'prescription' => Icons.medication_outlined,
    'imaging' => Icons.image_search_outlined,
    'diagnosis' || 'consultation' => Icons.medical_information_outlined,
    'vaccination' => Icons.vaccines_outlined,
    'vital' => Icons.monitor_heart_outlined,
    _ => Icons.folder_outlined,
  };

  Color get tone => switch (type) {
    'prescription' => AppColors.primary,
    'imaging' => AppColors.info,
    'diagnosis' => AppColors.critical,
    'vaccination' => AppColors.normal,
    'vital' => AppColors.primary,
    _ => AppColors.mutedInk,
  };

  BadgeTone get badgeTone => switch (type) {
    'diagnosis' => BadgeTone.critical,
    'vital' => BadgeTone.info,
    _ => BadgeTone.neutral,
  };
}

// ── Référence plage normale pour analyses ─────────────────────────
class LabReference {
  final String vitalType;
  final double? min;
  final double? max;
  final String unit;
  final String label;

  const LabReference({
    required this.vitalType,
    this.min,
    this.max,
    required this.unit,
    required this.label,
  });

  static const _references = <String, LabReference>{
    'hba1c': LabReference(
      vitalType: 'hba1c',
      min: 0,
      max: 5.7,
      unit: '%',
      label: 'HbA1c',
    ),
    'glucose': LabReference(
      vitalType: 'glucose',
      min: 0.7,
      max: 1.1,
      unit: 'g/L',
      label: 'Glycémie',
    ),
    'creatinine': LabReference(
      vitalType: 'creatinine',
      min: 0.6,
      max: 1.2,
      unit: 'mg/dL',
      label: 'Créatinine',
    ),
    'hemoglobin': LabReference(
      vitalType: 'hemoglobin',
      min: 12.0,
      max: 17.5,
      unit: 'g/dL',
      label: 'Hémoglobine',
    ),
    'wbc': LabReference(
      vitalType: 'wbc',
      min: 4.0,
      max: 11.0,
      unit: 'G/L',
      label: 'Leucocytes',
    ),
    'platelets': LabReference(
      vitalType: 'platelets',
      min: 150,
      max: 400,
      unit: 'G/L',
      label: 'Plaquettes',
    ),
    'cholesterol': LabReference(
      vitalType: 'cholesterol',
      min: 0,
      max: 2.0,
      unit: 'g/L',
      label: 'Cholestérol',
    ),
    'ldl': LabReference(
      vitalType: 'ldl',
      min: 0,
      max: 1.6,
      unit: 'g/L',
      label: 'LDL',
    ),
    'hdl': LabReference(
      vitalType: 'hdl',
      min: 0.4,
      max: 2.0,
      unit: 'g/L',
      label: 'HDL',
    ),
    'urea': LabReference(
      vitalType: 'urea',
      min: 0.1,
      max: 0.5,
      unit: 'g/L',
      label: 'Urée',
    ),
    'tsh': LabReference(
      vitalType: 'tsh',
      min: 0.4,
      max: 4.0,
      unit: 'mUI/L',
      label: 'TSH',
    ),
    'crp': LabReference(
      vitalType: 'crp',
      min: 0,
      max: 6.0,
      unit: 'mg/L',
      label: 'CRP',
    ),
  };

  static LabReference? forType(String type) => _references[type];

  bool isOutOfRange(double value) {
    if (min != null && value < min!) return true;
    if (max != null && value > max!) return true;
    return false;
  }

  bool isCritical(double value) {
    if (min != null && value < min! * 0.7) return true;
    if (max != null && value > max! * 1.5) return true;
    return false;
  }
}

class AllergyItem {
  final int id;
  final String allergen;
  final String severity;
  final String notes;
  const AllergyItem({
    required this.id,
    required this.allergen,
    required this.severity,
    required this.notes,
  });
  factory AllergyItem.fromJson(Map<String, dynamic> j) => AllergyItem(
    id: (j['id'] as num?)?.toInt() ?? 0, // ← (num?)?.toInt()
    allergen: j['allergen'] as String? ?? '',
    severity: j['severity'] as String? ?? 'medium',
    notes: j['notes'] as String? ?? '',
  );
}

// ── PrescriptionItem ───────────────────────────────────────────────
class PrescriptionItem {
  final int id;
  final int patientId;
  final int doctorId;
  final String medicationName;
  final String dosage;
  final String frequency;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String instructions;
  final bool isRenewable;
  const PrescriptionItem({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.instructions,
    this.isRenewable = false,
  });
  String? get formattedStartDate => _formatDt(startDate);
  String? get formattedEndDate => _formatDt(endDate);

  static String? _formatDt(DateTime? dt) {
    if (dt == null) return null;
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  factory PrescriptionItem.fromJson(Map<String, dynamic> j) {
    return PrescriptionItem(
      id: (j['id'] as num?)?.toInt() ?? 0,
      medicationName: j['medication_name'] as String? ?? '',
      dosage: j['dosage'] as String? ?? '',
      frequency: j['frequency'] as String? ?? '',
      status: j['status'] as String? ?? 'active',
      startDate: DateTime.parse(j['start_date'] as String? ?? ''),
      endDate: DateTime.parse(j['end_date'] as String? ?? ''),
      instructions: j['instructions'] as String? ?? '',
      patientId: (j['patient_id'] as num?)?.toInt() ?? 0,
      doctorId: (j['doctor_id'] as num?)?.toInt() ?? 0,
      isRenewable: j['is_renewable'] as bool? ?? false,
    );
  }
}

// ── VitalItem ──────────────────────────────────────────────────────
class VitalItem {
  final int id;
  final String vitalType;
  final double value;
  final String unit;
  final String recordedAt;
  const VitalItem({
    required this.id,
    required this.vitalType,
    required this.value,
    required this.unit,
    required this.recordedAt,
  });
  factory VitalItem.fromJson(Map<String, dynamic> j) => VitalItem(
    id: (j['id'] as num?)?.toInt() ?? 0, // ← fix
    vitalType: j['vital_type'] as String? ?? '',
    value: (j['value'] as num?)?.toDouble() ?? 0.0, // ← fix
    unit: j['unit'] as String? ?? '',
    recordedAt: j['recorded_at'] as String? ?? '',
  );

  String get typeLabel => switch (vitalType) {
    'weight' => 'Poids',
    'heart_rate' => 'Fréquence cardiaque',
    'blood_pressure' => 'Tension artérielle',
    'temperature' => 'Température',
    'oxygen_saturation' => 'Saturation O₂',
    'blood_sugar' => 'Glycémie',
    _ => vitalType,
  };
}

// ── VaccinationItem ────────────────────────────────────────────────
class VaccinationItem {
  final int id;
  final String vaccineName;
  final int dosesReceived;
  final int dosesRequired;
  final String status;
  final String lastDoseDate;
  final String nextDoseDate;
  final String recordedAt;
  const VaccinationItem({
    required this.id,
    required this.vaccineName,
    required this.dosesReceived,
    required this.dosesRequired,
    required this.status,
    required this.lastDoseDate,
    required this.nextDoseDate,
    required this.recordedAt,
  });
  String get formattedDate {
    try {
      final dt = DateTime.parse(recordedAt);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return recordedAt;
    }
  }

  factory VaccinationItem.fromJson(Map<String, dynamic> j) => VaccinationItem(
    id: (j['id'] as num?)?.toInt() ?? 0, // ← fix
    vaccineName: j['vaccine_name'] as String? ?? '',
    dosesReceived: (j['doses_received'] as num?)?.toInt() ?? 0, // ← fix
    dosesRequired: (j['doses_required'] as num?)?.toInt() ?? 1, // ← fix
    lastDoseDate: j['last_dose_date'] as String? ?? '',
    nextDoseDate: j['next_dose_date'] as String? ?? '',
    status: j['status'] as String? ?? 'pending',
    recordedAt: j['recorded_at'] as String? ?? '',
  );
  double get progress => dosesRequired > 0 ? dosesReceived / dosesRequired : 0;
}

// ── MedicalRecordItem ──────────────────────────────────────────────
class MedicalRecordItem {
  final int id;
  final String title;
  final String recordType;
  final String notes;
  final String createdAt;
  final String doctorName;
  const MedicalRecordItem({
    required this.id,
    required this.title,
    required this.recordType,
    required this.notes,
    required this.createdAt,
    required this.doctorName,
  });
  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return createdAt;
    }
  }

  factory MedicalRecordItem.fromJson(Map<String, dynamic> j) {
    final doc = j['doctors'] as Map<String, dynamic>?;
    return MedicalRecordItem(
      id: (j['id'] as num?)?.toInt() ?? 0, // ← fix
      title: j['title'] as String? ?? '',
      recordType: j['record_type'] as String? ?? 'consultation',
      notes: j['notes'] as String? ?? '',
      createdAt: j['created_at'] as String? ?? '',
      doctorName: doc != null
          ? 'Dr. ${doc['first_name'] ?? ''} ${doc['last_name'] ?? ''}'.trim()
          : 'Médecin',
    );
  }
}

// ── PatientOverviewData ────────────────────────────────────────────
class PatientOverviewData {
  final int? age;
  final String? gender;
  final List<AllergyItem> allergies;
  final List<PrescriptionItem> activePrescriptions;
  final int diagnosesCount;
  final int vaccinesCount;
  final int completedVaccinesCount;
  final List<VitalItem> latestVitals;
  final OverviewLastVisit? lastAppointment;

  const PatientOverviewData({
    this.age,
    this.gender,
    required this.allergies,
    required this.activePrescriptions,
    required this.diagnosesCount,
    required this.vaccinesCount,
    required this.completedVaccinesCount,
    required this.latestVitals,
    this.lastAppointment,
  });

  VitalItem? latestVital(String type) {
    try {
      return latestVitals.firstWhere((v) => v.vitalType == type);
    } catch (_) {
      return null;
    }
  }

  factory PatientOverviewData.fromJson(Map<String, dynamic> json) {
    final patient = json['patient'] as Map<String, dynamic>? ?? {};
    final allergRaw = json['allergies'] as List? ?? [];
    final prescRaw = json['activePrescriptions'] as List? ?? [];
    final vitalsRaw = json['latestVitals'] as List? ?? [];
    final apptRaw = json['lastAppointment'] as Map<String, dynamic>?;

    return PatientOverviewData(
      // ← (num?)?.toInt() pour tous les champs int
      age: (patient['age'] as num?)?.toInt(),
      gender: patient['gender'] as String?,
      allergies: allergRaw
          .map((e) => AllergyItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      activePrescriptions: prescRaw
          .map((e) => PrescriptionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      diagnosesCount: (json['diagnosesCount'] as num?)?.toInt() ?? 0,
      vaccinesCount: (json['vaccinesCount'] as num?)?.toInt() ?? 0,
      completedVaccinesCount:
          (json['completedVaccinesCount'] as num?)?.toInt() ?? 0,
      latestVitals: vitalsRaw
          .map((e) => VitalItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastAppointment: apptRaw != null
          ? OverviewLastVisit.fromJson(apptRaw)
          : null,
    );
  }
}

class OverviewLastVisit {
  final String date;
  final String? reason;
  final String? doctorName;
  const OverviewLastVisit({required this.date, this.reason, this.doctorName});
  factory OverviewLastVisit.fromJson(Map<String, dynamic> json) {
    final doc = json['doctors'] as Map<String, dynamic>?;
    String dateLabel = json['appointment_date'] as String? ?? '';
    try {
      final dt = DateTime.parse(dateLabel);
      dateLabel =
          '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {}
    return OverviewLastVisit(
      date: dateLabel,
      reason: json['reason'] as String?,
      doctorName: doc != null
          ? 'Dr. ${doc['first_name'] ?? ''} ${doc['last_name'] ?? ''}'.trim()
          : null,
    );
  }
}

// enum DossierSection {
//   overview,
//   allergies,
//   prescriptions,
//   vitals,
//   vaccinations,
//   medicalRecords;

//   String get label => switch (this) {
//     DossierSection.overview       => 'Résumé',
//     DossierSection.allergies      => 'Allergies',
//     DossierSection.prescriptions  => 'Ordonnances',
//     DossierSection.vitals         => 'Constantes',
//     DossierSection.vaccinations   => 'Vaccins',
//     DossierSection.medicalRecords => 'Dossiers',
//   };

//   // ← 'overview' est une section séparée traitée par loadOverview
//   // Les autres sections → loadSection (retourne List)
//   String get apiKey => switch (this) {
//     DossierSection.overview       => 'overview',
//     DossierSection.allergies      => 'allergies',
//     DossierSection.prescriptions  => 'prescriptions',
//     DossierSection.vitals         => 'vitals',
//     DossierSection.vaccinations   => 'vaccinations',
//     DossierSection.medicalRecords => 'medical_records',
//   };

//   IconData get icon => switch (this) {
//     DossierSection.overview       => Icons.dashboard_outlined,
//     DossierSection.allergies      => Icons.warning_amber_outlined,
//     DossierSection.prescriptions  => Icons.medication_outlined,
//     DossierSection.vitals         => Icons.monitor_heart_outlined,
//     DossierSection.vaccinations   => Icons.vaccines_outlined,
//     DossierSection.medicalRecords => Icons.folder_shared_outlined,
//   };
// }

// // ── AllergyItem ────────────────────────────────────────────────────
// class AllergyItem {
//   final int    id;
//   final String allergen;
//   final String severity;
//   final String notes;
//   const AllergyItem({
//     required this.id,
//     required this.allergen,
//     required this.severity,
//     required this.notes,
//   });
//   factory AllergyItem.fromJson(Map<String, dynamic> j) => AllergyItem(
//     id:       (j['id'] as num?)?.toInt() ?? 0,       // ← (num?)?.toInt()
//     allergen: j['allergen'] as String? ?? '',
//     severity: j['severity'] as String? ?? 'medium',
//     notes:    j['notes']    as String? ?? '',
//   );
// }

// // ── PrescriptionItem ───────────────────────────────────────────────
// class PrescriptionItem {
//   final int    id;
//   final String medicationName;
//   final String dosage;
//   final String frequency;
//   final String status;
//   final String startDate;
//   final String endDate;
//   final String instructions;
//   final String doctorName;
//   const PrescriptionItem({
//     required this.id,
//     required this.medicationName,
//     required this.dosage,
//     required this.frequency,
//     required this.status,
//     required this.startDate,
//     required this.endDate,
//     required this.instructions,
//     required this.doctorName,
//   });
//   factory PrescriptionItem.fromJson(Map<String, dynamic> j) {
//     final doc = j['doctors'] as Map<String, dynamic>?;
//     return PrescriptionItem(
//       id:             (j['id'] as num?)?.toInt() ?? 0,  // ← fix
//       medicationName: j['medication_name'] as String? ?? '',
//       dosage:         j['dosage']          as String? ?? '',
//       frequency:      j['frequency']       as String? ?? '',
//       status:         j['status']          as String? ?? 'active',
//       startDate:      j['start_date']      as String? ?? '',
//       endDate:        j['end_date']        as String? ?? '',
//       instructions:   j['instructions']    as String? ?? '',
//       doctorName:     doc != null
//           ? 'Dr. ${doc['first_name'] ?? ''} ${doc['last_name'] ?? ''}'.trim()
//           : 'Médecin',
//     );
//   }
// }

// // ── VitalItem ──────────────────────────────────────────────────────
// class VitalItem {
//   final int    id;
//   final String vitalType;
//   final double value;
//   final String unit;
//   final String recordedAt;
//   const VitalItem({
//     required this.id,
//     required this.vitalType,
//     required this.value,
//     required this.unit,
//     required this.recordedAt,
//   });
//   factory VitalItem.fromJson(Map<String, dynamic> j) => VitalItem(
//     id:         (j['id']    as num?)?.toInt()    ?? 0,   // ← fix
//     vitalType:  j['vital_type'] as String? ?? '',
//     value:      (j['value'] as num?)?.toDouble() ?? 0.0, // ← fix
//     unit:       j['unit']       as String? ?? '',
//     recordedAt: j['recorded_at'] as String? ?? '',
//   );

//   String get typeLabel => switch (vitalType) {
//     'weight'            => 'Poids',
//     'heart_rate'        => 'Fréquence cardiaque',
//     'blood_pressure'    => 'Tension artérielle',
//     'temperature'       => 'Température',
//     'oxygen_saturation' => 'Saturation O₂',
//     'blood_sugar'       => 'Glycémie',
//     _                   => vitalType,
//   };
// }

// // ── VaccinationItem ────────────────────────────────────────────────
// class VaccinationItem {
//   final int    id;
//   final String vaccineName;
//   final int    dosesReceived;
//   final int    dosesRequired;
//   final String status;
//   final String lastDoseDate;
//   final String nextDoseDate;
//   const VaccinationItem({
//     required this.id,
//     required this.vaccineName,
//     required this.dosesReceived,
//     required this.dosesRequired,
//     required this.status,
//     required this.lastDoseDate,
//     required this.nextDoseDate,
//   });
//   factory VaccinationItem.fromJson(Map<String, dynamic> j) => VaccinationItem(
//     id:            (j['id']             as num?)?.toInt() ?? 0,  // ← fix
//     vaccineName:   j['vaccine_name']  as String? ?? '',
//     dosesReceived: (j['doses_received'] as num?)?.toInt() ?? 0,  // ← fix
//     dosesRequired: (j['doses_required'] as num?)?.toInt() ?? 1,  // ← fix
//     status:        j['status']        as String? ?? 'pending',
//     lastDoseDate:  j['last_dose_date'] as String? ?? '',
//     nextDoseDate:  j['next_dose_date'] as String? ?? '',
//   );
//   double get progress => dosesRequired > 0
//       ? dosesReceived / dosesRequired
//       : 0;
// }

// // ── MedicalRecordItem ──────────────────────────────────────────────
// class MedicalRecordItem {
//   final int    id;
//   final String title;
//   final String recordType;
//   final String notes;
//   final String createdAt;
//   final String doctorName;
//   const MedicalRecordItem({
//     required this.id,
//     required this.title,
//     required this.recordType,
//     required this.notes,
//     required this.createdAt,
//     required this.doctorName,
//   });
//   factory MedicalRecordItem.fromJson(Map<String, dynamic> j) {
//     final doc = j['doctors'] as Map<String, dynamic>?;
//     return MedicalRecordItem(
//       id:         (j['id'] as num?)?.toInt() ?? 0,   // ← fix
//       title:      j['title']       as String? ?? '',
//       recordType: j['record_type'] as String? ?? 'consultation',
//       notes:      j['notes']       as String? ?? '',
//       createdAt:  j['created_at']  as String? ?? '',
//       doctorName: doc != null
//           ? 'Dr. ${doc['first_name'] ?? ''} ${doc['last_name'] ?? ''}'.trim()
//           : 'Médecin',
//     );
//   }
// }

// // ── PatientOverviewData ────────────────────────────────────────────
// class PatientOverviewData {
//   final int?    age;
//   final String? gender;
//   final List<AllergyItem>       allergies;
//   final List<PrescriptionItem>  activePrescriptions;
//   final int     diagnosesCount;
//   final int     vaccinesCount;
//   final int     completedVaccinesCount;
//   final List<VitalItem>         latestVitals;
//   final OverviewLastVisit?      lastAppointment;

//   const PatientOverviewData({
//     this.age,
//     this.gender,
//     required this.allergies,
//     required this.activePrescriptions,
//     required this.diagnosesCount,
//     required this.vaccinesCount,
//     required this.completedVaccinesCount,
//     required this.latestVitals,
//     this.lastAppointment,
//   });

//   VitalItem? latestVital(String type) {
//     try {
//       return latestVitals.firstWhere((v) => v.vitalType == type);
//     } catch (_) {
//       return null;
//     }
//   }

//   factory PatientOverviewData.fromJson(Map<String, dynamic> json) {
//     final patient   = json['patient']   as Map<String, dynamic>? ?? {};
//     final allergRaw = json['allergies'] as List? ?? [];
//     final prescRaw  = json['activePrescriptions'] as List? ?? [];
//     final vitalsRaw = json['latestVitals'] as List? ?? [];
//     final apptRaw   = json['lastAppointment'] as Map<String, dynamic>?;

//     return PatientOverviewData(
//       // ← (num?)?.toInt() pour tous les champs int
//       age:    (patient['age'] as num?)?.toInt(),
//       gender: patient['gender'] as String?,
//       allergies: allergRaw
//           .map((e) => AllergyItem.fromJson(e as Map<String, dynamic>))
//           .toList(),
//       activePrescriptions: prescRaw
//           .map((e) => PrescriptionItem.fromJson(e as Map<String, dynamic>))
//           .toList(),
//       diagnosesCount:         (json['diagnosesCount']         as num?)?.toInt() ?? 0,
//       vaccinesCount:          (json['vaccinesCount']          as num?)?.toInt() ?? 0,
//       completedVaccinesCount: (json['completedVaccinesCount'] as num?)?.toInt() ?? 0,
//       latestVitals: vitalsRaw
//           .map((e) => VitalItem.fromJson(e as Map<String, dynamic>))
//           .toList(),
//       lastAppointment: apptRaw != null
//           ? OverviewLastVisit.fromJson(apptRaw)
//           : null,
//     );
//   }
// }

// class OverviewLastVisit {
//   final String  date;
//   final String? reason;
//   final String? doctorName;
//   const OverviewLastVisit({
//     required this.date,
//     this.reason,
//     this.doctorName,
//   });
//   factory OverviewLastVisit.fromJson(Map<String, dynamic> json) {
//     final doc = json['doctors'] as Map<String, dynamic>?;
//     String dateLabel = json['appointment_date'] as String? ?? '';
//     try {
//       final dt = DateTime.parse(dateLabel);
//       dateLabel = '${dt.day.toString().padLeft(2,'0')}/'
//                   '${dt.month.toString().padLeft(2,'0')}/'
//                   '${dt.year}';
//     } catch (_) {}
//     return OverviewLastVisit(
//       date:       dateLabel,
//       reason:     json['reason']    as String?,
//       doctorName: doc != null
//           ? 'Dr. ${doc['first_name'] ?? ''} ${doc['last_name'] ?? ''}'.trim()
//           : null,
//     );
//   }
// }
