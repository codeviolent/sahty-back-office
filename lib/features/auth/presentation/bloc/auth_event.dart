import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested({required this.email, required this.password});
  @override List<Object> get props => [email, password];
}
class AuthDeviceApproved extends AuthEvent {}
class AuthLogoutRequested extends AuthEvent {}

class AuthSessionRestored extends AuthEvent {
  final String jwt;
  const AuthSessionRestored(this.jwt);
  @override List<Object> get props => [jwt];
}
class AuthSessionCheckRequested extends AuthEvent {}