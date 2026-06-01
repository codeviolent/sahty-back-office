import 'package:equatable/equatable.dart';

class AuthResult extends Equatable {
  final String jwt;
  final String userId;
  final String role;
  final String doctorName;
  final int? doctorId;
  final String? refreshToken;

  const AuthResult({
    required this.jwt,
    required this.userId,
    required this.role,
    required this.doctorName,
    this.doctorId,
    this.refreshToken,
  });

  @override
  List<Object?> get props => [
    jwt,
    userId,
    role,
    doctorName,
    doctorId,
    refreshToken,
  ];
}
