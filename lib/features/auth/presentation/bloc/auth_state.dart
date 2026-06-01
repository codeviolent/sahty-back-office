import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override List<Object?> get props => [];
}

class AuthInitial       extends AuthState {}
class AuthLoading        extends AuthState {}
class AuthLoggedOut      extends AuthState {}

class AuthPendingDeviceTrust extends AuthState {
  final String jwt;
  final String role;
  final String userId;
  final String doctorName;

  const AuthPendingDeviceTrust({
    required this.jwt,
    required this.role,
    required this.userId,
    required this.doctorName,
  });
  @override List<Object> get props => [jwt, role, userId];
}

class AuthAuthenticated extends AuthState {
  final String jwt;
  final String role;
  final String userId;
  final String doctorName;

  const AuthAuthenticated({
    required this.jwt,
    required this.role,
    required this.userId,
    required this.doctorName,
  });

  @override List<Object> get props => [jwt, role, userId];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override List<Object> get props => [message];
}

class AuthDeviceTrustRequired extends AuthState {
  final String jwt;
  final String role;
  final String userId;
  final String doctorName;

  const AuthDeviceTrustRequired({
    required this.jwt,
    required this.role,
    required this.userId,
    required this.doctorName,
  });

  @override List<Object> get props => [jwt, role, userId];
}