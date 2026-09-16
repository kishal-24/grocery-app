import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // =========================
  // LOGIN
  // =========================

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }


  // =========================
  // SIGNUP
  // =========================

  Future<UserCredential> signup({
    required String email,
    required String password,
  }) async {
    final userCredential =
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Send verification link
    await userCredential.user!.sendEmailVerification();

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
    await _firebaseAuth.currentUser?.reload();

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
    await _firebaseAuth.sendPasswordResetEmail(
      email: email,
    );
  }
}