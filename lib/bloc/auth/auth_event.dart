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
  final String usernameOrEmail;
  final String password;

  const LoginEvent({
    String? usernameOrEmail,
    String? email,
    required this.password,
  }) : usernameOrEmail = usernameOrEmail ?? email ?? '';

  String get email => usernameOrEmail;

  @override
  List<Object?> get props => [
        usernameOrEmail,
        password,
      ];
}

// =========================
// SIGNUP
// =========================

class SignupEvent extends AuthEvent {
  final String email;
  final String password;
  final String? username;

  const SignupEvent({
    required this.email,
    required this.password,
    this.username,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        username,
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