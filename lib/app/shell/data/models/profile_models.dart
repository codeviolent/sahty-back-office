// ── Modèle commun à tous les rôles ────────────────────────────────
import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String userId;
  final String role;
  final String firstName;
  final String lastName;
  final String specialty; // spécialité ou fonction
  final String city;
  final String? photoUrl;
  final String? phone;
  final int unreadMessages;
  final List<AgendaItem> todayAgenda;
  final ProfileStats stats;

  const UserProfile({
    required this.userId,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.specialty,
    required this.city,
    required this.unreadMessages,
    required this.todayAgenda,
    required this.stats,
    this.photoUrl,
    this.phone,
  });

  String get displayName => '$firstName $lastName'.trim();
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l'.isNotEmpty ? '$f$l' : role[0].toUpperCase();
  }

  bool get isMedecin => role == 'medecin';
  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';
  bool get isPharma => role == 'pharmacien';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final p = json['profile'] as Map<String, dynamic>? ?? json;
    return UserProfile(
      userId: p['userId'] as String? ?? '',
      role: p['role'] as String? ?? 'medecin',
      firstName: p['firstName'] as String? ?? '',
      lastName: p['lastName'] as String? ?? '',
      specialty: p['specialty'] as String? ?? '',
      city: p['city'] as String? ?? '',
      photoUrl: p['photoUrl'] as String?,
      phone: p['phone'] as String?,
      unreadMessages: p['unreadMessages'] as int? ?? 0,
      todayAgenda: (p['todayAgenda'] as List? ?? [])
          .map((e) => AgendaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      stats: ProfileStats.fromJson(
        p['stats'] as Map<String, dynamic>? ?? {},
        role: p['role'] as String? ?? 'medecin',
      ),
    );
  }
  @override
  List<Object?> get props => [
    userId,
    role,
    firstName,
    lastName,
    specialty,
    city,
    photoUrl,
    phone,
    unreadMessages,
    todayAgenda,
    stats,
  ];
}

// ── Agenda du jour (panel latéral) ────────────────────────────────
class AgendaItem extends Equatable {
  final int id;
  final String time;
  final String endTime;
  final String patientName;
  final String reason;
  final String status;

  const AgendaItem({
    required this.id,
    required this.time,
    required this.endTime,
    required this.patientName,
    required this.reason,
    required this.status,
  });

  factory AgendaItem.fromJson(Map<String, dynamic> json) {
    return AgendaItem(
      id: json['id'] as int? ?? 0,
      time: json['time'] as String? ?? '--:--',
      endTime: json['endTime'] as String? ?? '--:--',
      patientName: json['patientName'] as String? ?? 'Patient',
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
    );
  }

  @override
  List<Object?> get props => [
    id,
    time,
    endTime,
    patientName,
    reason,
    status,
  ];
}

// ── Stats selon le rôle ────────────────────────────────────────────
class ProfileStats extends Equatable {
  // Médecin
  final String department;
  final bool isAvailable;
  final String workingHours;
  final double rating;

  // Admin
  final int totalPatients;
  final int totalDoctors;
  final int rdvToday;

  // Staff
  final int rdvPending;
  final int rdvTotal;

  // Pharmacien
  final int dispensationsToday;
  final int prescriptionsActive;

  const ProfileStats({
    this.department = '',
    this.isAvailable = true,
    this.workingHours = '--',
    this.rating = 0,
    this.totalPatients = 0,
    this.totalDoctors = 0,
    this.rdvToday = 0,
    this.rdvPending = 0,
    this.rdvTotal = 0,
    this.dispensationsToday = 0,
    this.prescriptionsActive = 0,
  });

  factory ProfileStats.fromJson(
    Map<String, dynamic> json, {
    required String role,
  }) {
    return ProfileStats(
      department: json['department'] as String? ?? '',
      isAvailable: json['isAvailable'] as bool? ?? true,
      workingHours: json['workingHours'] as String? ?? '--',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalPatients: json['totalPatients'] as int? ?? 0,
      totalDoctors: json['totalDoctors'] as int? ?? 0,
      rdvToday: json['rdvToday'] as int? ?? 0,
      rdvPending: json['rdvPending'] as int? ?? 0,
      rdvTotal: json['rdvTotal'] as int? ?? 0,
      dispensationsToday: json['dispensationsToday'] as int? ?? 0,
      prescriptionsActive: json['prescriptionsActive'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    department,
    isAvailable,
    workingHours,
    rating,
    totalPatients,
    totalDoctors,
    rdvToday,
    rdvPending,
    rdvTotal,
    dispensationsToday,
    prescriptionsActive,
  ];
}
