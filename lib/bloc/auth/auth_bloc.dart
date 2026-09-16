import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({
    required this.authRepository,
  }) : super(const AuthState()) {

    // =========================
    // LOGIN
    // =========================

    on<LoginEvent>((event, emit) async {
      emit(
        state.copyWith(
          status: AuthStatus.loading,
          errorMessage: null,
        ),
      );

      try {
        final userCredential = await authRepository.login(
          email: event.email,
          password: event.password,
        );

        // Refresh Firebase user information
        await userCredential.user?.reload();

        final user = FirebaseAuth.instance.currentUser;

        // Check email verification
        if (user != null && user.emailVerified) {
          emit(
            state.copyWith(
              status: AuthStatus.success,
              errorMessage: null,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: AuthStatus.emailNotVerified,
              errorMessage:
              'Please verify your email before logging in.',
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            errorMessage: getFirebaseErrorMessage(e),
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            errorMessage: 'Something went wrong.',
          ),
        );
      }
    });




    on<SignupEvent>((event, emit) async {
      emit(
        state.copyWith(
          status: AuthStatus.loading,
          errorMessage: null,
        ),
      );

      try {
        await authRepository.signup(
          email: event.email,
          password: event.password,
        );

        emit(
          state.copyWith(
            status: AuthStatus.verificationSent,
            errorMessage: null,
          ),
        );
      } on FirebaseAuthException catch (e) {
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            errorMessage: getFirebaseErrorMessage(e),
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            errorMessage: 'Something went wrong.',
          ),
        );
      }
    });


    // =========================
    // SEND VERIFICATION EMAIL
    // =========================

    on<SendVerificationEmailEvent>((event, emit) async {
      emit(
        state.copyWith(
          status: AuthStatus.loading,
          errorMessage: null,
        ),
      );

      try {
        await authRepository.sendVerificationEmail();

        emit(
          state.copyWith(
            status: AuthStatus.verificationSent,
            errorMessage: null,
          ),
        );
      } on FirebaseAuthException catch (e) {
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            errorMessage: getFirebaseErrorMessage(e),
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            errorMessage: 'Unable to send verification email.',
          ),
        );
      }
    });


    // =========================
    // CHECK AUTH
    // =========================

    on<CheckAuthEvent>((event, emit) async {
      try {
        final user = authRepository.currentUser;

        if (user == null) {
          emit(
            state.copyWith(
              status: AuthStatus.initial,
            ),
          );

          return;
        }

        await user.reload();

        final updatedUser = FirebaseAuth.instance.currentUser;

        if (updatedUser != null &&
            updatedUser.emailVerified) {
          emit(
            state.copyWith(
              status: AuthStatus.success,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: AuthStatus.emailNotVerified,
            ),
          );
        }
      } catch (e) {
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            errorMessage: 'Unable to check account.',
          ),
        );
      }
    });


    // =========================
    // LOGOUT
    // =========================

    on<LogoutEvent>((event, emit) async {
      try {
        await authRepository.logout();

        emit(
          state.copyWith(
            status: AuthStatus.initial,
            errorMessage: null,
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            errorMessage: 'Logout failed.',
          ),
        );
      }
    });


    // =========================
    // FORGOT PASSWORD
    // =========================

    on<ForgotPasswordEvent>((event, emit) async {
      emit(
        state.copyWith(
          status: AuthStatus.loading,
          errorMessage: null,
        ),
      );

      try {
        await authRepository.forgotPassword(
          email: event.email,
        );

        emit(
          state.copyWith(
            status: AuthStatus.success,
            errorMessage: null,
          ),
        );
      } on FirebaseAuthException catch (e) {
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            errorMessage: getFirebaseErrorMessage(e),
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            errorMessage: 'Unable to send reset email.',
          ),
        );
      }
    });
  }


  // =========================
  // FIREBASE ERROR MESSAGE
  // =========================

  String getFirebaseErrorMessage(
      FirebaseAuthException e,
      ) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address.';

      case 'user-not-found':
        return 'No account found with this email.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';

      case 'email-already-in-use':
        return 'This email is already registered.';

      case 'weak-password':
        return 'Password should be at least 6 characters.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}