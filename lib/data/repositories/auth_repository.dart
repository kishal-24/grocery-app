import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_repository.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final UserRepository _userRepository = UserRepository();

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

    // 1. Check local cache in SharedPreferences first (instant)
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedEmail = prefs.getString('username_to_email_$lower');
      if (cachedEmail != null && cachedEmail.isNotEmpty) {
        return cachedEmail;
      }
    } catch (_) {}

    // 2. Check Cloud Firestore (enables login across different devices or fresh installs)
    try {
      final usernameDoc = await FirebaseFirestore.instance
          .collection('usernames')
          .doc(lower)
          .get()
          .timeout(const Duration(seconds: 4));

      if (usernameDoc.exists && usernameDoc.data()?['email'] != null) {
        final email = usernameDoc.data()!['email'] as String;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username_to_email_$lower', email);
        } catch (_) {}
        return email;
      }

      var querySnap = await FirebaseFirestore.instance
          .collection('users')
          .where('usernameLower', isEqualTo: lower)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 4));

      if (querySnap.docs.isEmpty) {
        querySnap = await FirebaseFirestore.instance
            .collection('users')
            .where('username_lowercase', isEqualTo: lower)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 4));
      }

      if (querySnap.docs.isNotEmpty) {
        final email = querySnap.docs.first.data()['email'] as String?;
        if (email != null && email.isNotEmpty) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('username_to_email_$lower', email);
          } catch (_) {}
          return email;
        }
      }
    } catch (_) {}

    // Fallback: If not found in local cache or Firestore
    throw FirebaseAuthException(
      code: 'user-not-found',
      message: 'No account found for username "$input". Please check your username or log in with your email address.',
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

    // Cache username to email locally upon login and sync to Firestore
    try {
      final user = credential.user;
      final prefs = await SharedPreferences.getInstance();
      final effectiveEmail = user?.email ?? email;

      if (user?.displayName != null && user!.displayName!.isNotEmpty) {
        final dName = user.displayName!.trim();
        await prefs.setString(
          'username_to_email_${dName.toLowerCase()}',
          effectiveEmail,
        );
        try {
          await FirebaseFirestore.instance
              .collection('usernames')
              .doc(dName.toLowerCase())
              .set({
            'email': effectiveEmail,
            'uid': user.uid,
          }, SetOptions(merge: true));
        } catch (_) {}
      }

      if (!usernameOrEmail.contains('@')) {
        final lower = usernameOrEmail.trim().toLowerCase();
        await prefs.setString(
          'username_to_email_$lower',
          effectiveEmail,
        );
        try {
          await FirebaseFirestore.instance
              .collection('usernames')
              .doc(lower)
              .set({
            'email': effectiveEmail,
            'uid': user?.uid,
          }, SetOptions(merge: true));
        } catch (_) {}
      }

      if (user != null) {
        try {
          final profileDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 4));
          if (!profileDoc.exists) {
            await _userRepository.createUserProfile(
              user: user,
              username: user.displayName,
              name: user.displayName,
            );
          }
        } catch (_) {}
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

    final user = userCredential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-creation-failed',
        message: 'Unable to create your account.',
      );
    }

    // Save username in Firebase Authentication
    if (cleanUsername != null && cleanUsername.isNotEmpty) {
      await user.updateDisplayName(cleanUsername);

      // Refresh local Firebase user object
      await user.reload();
    }

    // Create production Firestore user profile with complete details
    await _userRepository.createUserProfile(
      user: user,
      username: cleanUsername,
      name: cleanUsername,
    );

    // Keep the existing local cache for now.
    // We will remove this dependency later.
    if (cleanUsername != null && cleanUsername.isNotEmpty) {
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

    // Send email verification
    try {
      await user.sendEmailVerification();
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