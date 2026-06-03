import 'package:equatable/equatable.dart';

import '../../../../core/widgets/status_badge.dart';

enum PatientAccessStatus {
  activeSession, // session en cours (< 1h)
  needsReason, // peut accéder via QR+PIN
  restricted; // accès restreint

  String get label => switch (this) {
    PatientAccessStatus.activeSession => 'Session active',
    PatientAccessStatus.needsReason => 'Accès via QR',
    PatientAccessStatus.restricted => 'Restreint',
  };

  BadgeTone get tone => switch (this) {
    PatientAccessStatus.activeSession => BadgeTone.normal,
    PatientAccessStatus.needsReason => BadgeTone.neutral,
    PatientAccessStatus.restricted => BadgeTone.critical,
  };
}

class PatientSearchResult extends Equatable {
  final int patientId;
  final String firstName;
  final String lastName;
  final String fullName;
  final String nniMasked;
  final int? age;
  final String? gender;
  final String bloodType;
  final String? qrToken;
  final String? lastVisit;
  final String lastReason;
  final bool hasActiveSession;
  final PatientAccessStatus accessStatus;

  const PatientSearchResult({
    required this.patientId,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.nniMasked,
    required this.age,
    required this.gender,
    required this.bloodType,
    required this.hasActiveSession,
    required this.accessStatus,
    this.qrToken,
    this.lastVisit,
    this.lastReason = '',
  });

  factory PatientSearchResult.fromJson(Map<String, dynamic> json) {
    final statusStr = json['accessStatus'] as String? ?? 'needs_reason';
    final status = switch (statusStr) {
      'active_session' => PatientAccessStatus.activeSession,
      'restricted' => PatientAccessStatus.restricted,
      _ => PatientAccessStatus.needsReason,
    };

    return PatientSearchResult(
      patientId: json['patientId'] as int,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      nniMasked: json['nniMasked'] as String? ?? '**** **** ****',
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      bloodType: json['bloodType'] as String? ?? 'Inconnu',
      qrToken: json['qrToken'] as String?,
      lastVisit: json['lastVisit'] as String?,
      lastReason: json['lastReason'] as String? ?? '',
      hasActiveSession: json['hasActiveSession'] as bool? ?? false,
      accessStatus: status,
    );
  }

  // Formatter la dernière visite pour l'affichage
  String get lastVisitLabel {
    if (lastVisit == null) return 'Aucune visite';
    try {
      final dt = DateTime.parse(lastVisit!);
      final now = DateTime.now();
      final diff = now.difference(dt).inDays;
      if (diff == 0) return 'Aujourd\'hui';
      if (diff == 1) return 'Hier';
      if (diff < 7) return 'Il y a $diff jours';
      if (diff < 30) return 'Il y a ${diff ~/ 7} sem.';
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return lastVisit!;
    }
  }

  // Initiales pour l'avatar
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  @override
  List<Object?> get props => [
    patientId,
    firstName,
    lastName,
    nniMasked,
    age,
    gender,
    bloodType,
    qrToken,
    lastVisit,
    lastReason,
    hasActiveSession,
    accessStatus,
  ];
}

class PatientSearchState extends Equatable {
  final List<PatientSearchResult> allResults;
  final List<PatientSearchResult> filtered;
  final String query;
  final bool isLoading;
  final String? error;
  final int total;

  const PatientSearchState({
    this.allResults = const [],
    this.filtered = const [],
    this.query = '',
    this.isLoading = false,
    this.error,
    this.total = 0,
  });

  @override
  List<Object?> get props => [
    allResults,
    filtered,
    query,
    isLoading,
    error,
    total,
  ];

  PatientSearchState copyWith({
    List<PatientSearchResult>? allResults,
    List<PatientSearchResult>? filtered,
    String? query,
    bool? isLoading,
    String? error,
    int? total,
  }) => PatientSearchState(
    allResults: allResults ?? this.allResults,
    filtered: filtered ?? this.filtered,
    query: query ?? this.query,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    total: total ?? this.total,
  );
}
