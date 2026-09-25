import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // ============================================================
  // RESOLVE EMAIL FROM USERNAME OR EMAIL
  // ============================================================

  Future<String> resolveEmail(String usernameOrEmail) async {
    final input = usernameOrEmail.trim();

    if (input.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Please enter your username or email.',
      );
    }

    // If it's already an email
    if (input.contains('@')) {
      return input;
    }

    final lower = input.toLowerCase();

    // Check local cache in SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedEmail = prefs.getString('username_to_email_$lower');
      if (cachedEmail != null && cachedEmail.isNotEmpty) {
        return cachedEmail;
      }
    } catch (_) {}

    // Fallback: If not found in local cache
    throw FirebaseAuthException(
      code: 'user-not-found',
      message: 'No account found for username "$input". Please log in with your email address.',
    );
  }

  // =========================
  // LOGIN
  // =========================

  Future<UserCredential> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final email = await resolveEmail(usernameOrEmail);

    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Cache username to email locally upon login
    try {
      final user = credential.user;
      final prefs = await SharedPreferences.getInstance();
      if (user?.displayName != null && user!.displayName!.isNotEmpty) {
        await prefs.setString(
          'username_to_email_${user.displayName!.trim().toLowerCase()}',
          email,
        );
      }
      if (!usernameOrEmail.contains('@')) {
        await prefs.setString(
          'username_to_email_${usernameOrEmail.trim().toLowerCase()}',
          email,
        );
      }
    } catch (_) {}

    return credential;
  }

  // =========================
  // SIGNUP
  // =========================

  Future<UserCredential> signup({
    required String email,
    required String password,
    String? username,
  }) async {
    final cleanEmail = email.trim();
    final cleanUsername = username?.trim();

    final userCredential =
        await _firebaseAuth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    if (cleanUsername != null && cleanUsername.isNotEmpty) {
      try {
        await userCredential.user?.updateDisplayName(cleanUsername);
      } catch (_) {}

      // Cache locally in SharedPreferences immediately
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'username_to_email_${cleanUsername.toLowerCase()}',
          cleanEmail,
        );
        await prefs.setString(
          'email_to_username_${cleanEmail.toLowerCase()}',
          cleanUsername,
        );
      } catch (_) {}
    }

    // Send verification link (safely catches in case of rate limit)
    try {
      await userCredential.user?.sendEmailVerification();
    } catch (_) {}

    return userCredential;
  }

  // =========================
  // SEND VERIFICATION EMAIL
  // =========================

  Future<void> sendVerificationEmail() async {
    final user = _firebaseAuth.currentUser;

    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // =========================
  // CHECK EMAIL VERIFIED
  // =========================

  Future<bool> isEmailVerified() async {
    try {
      await _firebaseAuth.currentUser?.reload().timeout(const Duration(seconds: 5));
      await _firebaseAuth.currentUser?.getIdToken(true).timeout(const Duration(seconds: 5));
    } catch (_) {}

    final user = _firebaseAuth.currentUser;

    return user?.emailVerified ?? false;
  }

  // =========================
  // LOGOUT
  // =========================

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  // =========================
  // CURRENT USER
  // =========================

  User? get currentUser {
    return _firebaseAuth.currentUser;
  }

  // =========================
  // IS LOGGED IN
  // =========================

  bool get isLoggedIn {
    return _firebaseAuth.currentUser != null;
  }

  // =========================
  // FORGOT PASSWORD
  // =========================

  Future<void> forgotPassword({
    required String email,
  }) async {
    final resolvedEmail = await resolveEmail(email);
    await _firebaseAuth.sendPasswordResetEmail(
      email: resolvedEmail,
    );
  }
}