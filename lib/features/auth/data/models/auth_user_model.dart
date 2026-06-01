import 'package:equatable/equatable.dart';

class AuthUserModel extends Equatable{
  final String id;
  final String? email;
  final String? phone;
  final String role;
  final String? doctorName;
  final int?    doctorId;

  const AuthUserModel({
    required this.id,
    required this.role,
    this.email,
    this.phone,
    this.doctorName,
    this.doctorId,
  });

  bool get isMedecin    => role == 'medecin';
  bool get isAdmin      => role == 'admin';
  bool get isStaff      => role == 'staff';
  bool get isPharma     => role == 'pharmacien';

  @override
  List<Object?> get props => [
    id, email, phone, role, doctorName, doctorId
  ];
}