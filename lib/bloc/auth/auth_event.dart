import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}


// =========================
// LOGIN
// =========================

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [
    email,
    password,
  ];
}


// =========================
// SIGNUP
// =========================

class SignupEvent extends AuthEvent {
  final String email;
  final String password;

  const SignupEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [
    email,
    password,
  ];
}


// =========================
// LOGOUT
// =========================

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}


// =========================
// CHECK AUTH
// =========================

class CheckAuthEvent extends AuthEvent {
  const CheckAuthEvent();
}


// =========================
// SEND VERIFICATION EMAIL
// =========================

class SendVerificationEmailEvent extends AuthEvent {
  const SendVerificationEmailEvent();
}


// =========================
// FORGOT PASSWORD
// =========================

class ForgotPasswordEvent extends AuthEvent {
  final String email;

  const ForgotPasswordEvent({
    required this.email,
  });

  @override
  List<Object?> get props => [
    email,
  ];
}