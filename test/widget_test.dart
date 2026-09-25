import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_app/bloc/auth/auth_event.dart';
import 'package:grocery_app/bloc/auth/auth_state.dart';

void main() {
  group('Auth Unit Tests', () {
    test('AuthState defaults to initial status', () {
      const state = AuthState();
      expect(state.status, AuthStatus.initial);
      expect(state.errorMessage, isNull);
    });

    test('AuthState copyWith updates fields correctly', () {
      const state = AuthState();
      final updated = state.copyWith(
        status: AuthStatus.loading,
        errorMessage: 'Test error',
      );
      expect(updated.status, AuthStatus.loading);
      expect(updated.errorMessage, 'Test error');
    });

    test('LoginEvent creates with email and password', () {
      const event = LoginEvent(email: 'test@example.com', password: 'password123');
      expect(event.email, 'test@example.com');
      expect(event.password, 'password123');
    });

    test('SignupEvent supports username, email, and password', () {
      const event = SignupEvent(
        email: 'test@example.com',
        password: 'password123',
        username: 'TestUser',
      );
      expect(event.email, 'test@example.com');
      expect(event.password, 'password123');
      expect(event.username, 'TestUser');
    });
  });
}
