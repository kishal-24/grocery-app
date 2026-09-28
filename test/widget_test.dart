import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_app/bloc/auth/auth_event.dart';
import 'package:grocery_app/bloc/auth/auth_state.dart';
import 'package:grocery_app/data/services/account_storage_service.dart';
import 'package:grocery_app/widgets/user_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      expect(event.usernameOrEmail, 'test@example.com');
      expect(event.password, 'password123');
    });

    test('LoginEvent creates with username and password', () {
      const event = LoginEvent(usernameOrEmail: 'alex_j', password: 'password123');
      expect(event.usernameOrEmail, 'alex_j');
      expect(event.email, 'alex_j');
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

  group('User Profile & Avatar Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('AccountStorageService saves and retrieves custom image', () async {
      final storage = AccountStorageService();
      const testImageBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

      await storage.saveUserProfile(
        name: 'Jane Doe',
        customImage: testImageBase64,
      );

      final profile = await storage.getUserProfile();
      expect(profile['name'], 'Jane Doe');
      expect(profile['customImage'], testImageBase64);

      // Clearing custom image
      await storage.saveUserProfile(clearCustomImage: true);
      final clearedProfile = await storage.getUserProfile();
      expect(clearedProfile['customImage'], '');
    });

    testWidgets('UserAvatar renders fallback avatar icon when customImage is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              avatarIndex: 0,
              radius: 30,
            ),
          ),
        ),
      );

      expect(find.byType(UserAvatar), findsOneWidget);
      expect(find.byIcon(AvatarConstants.icons[0]), findsOneWidget);
    });

    testWidgets('UserAvatar renders camera badge and handles tap callback', (tester) async {
      var badgeTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              avatarIndex: 1,
              radius: 35,
              showCameraBadge: true,
              onCameraTap: () {
                badgeTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pump();

      expect(badgeTapped, isTrue);
    });

    testWidgets('UserAvatar handles custom base64 image without crashing', (tester) async {
      // 1x1 transparent png in base64
      const tinyPng =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              customImage: tinyPng,
              avatarIndex: 0,
              radius: 30,
            ),
          ),
        ),
      );

      expect(find.byType(UserAvatar), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
