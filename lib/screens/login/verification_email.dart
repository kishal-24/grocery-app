import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../core/constants/app_colors.dart';
import '../main/main_screen.dart';

class VerificationEmailScreen extends StatefulWidget {
  const VerificationEmailScreen({super.key});

  @override
  State<VerificationEmailScreen> createState() =>
      _VerificationEmailScreenState();
}

class _VerificationEmailScreenState extends State<VerificationEmailScreen>
    with WidgetsBindingObserver {
  bool isChecking = false;
  bool isResending = false;
  Timer? _verificationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Periodically check with safe interval (8s) so Firebase rate limits are never triggered
    _verificationTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      checkEmailVerification(silent: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _verificationTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns to the app from checking their email app
    if (state == AppLifecycleState.resumed) {
      checkEmailVerification(silent: true);
    }
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  // ============================================================
  // CHECK EMAIL VERIFICATION
  // ============================================================

  Future<void> checkEmailVerification({bool silent = false}) async {
    if (isChecking) return;

    if (!silent) {
      setState(() {
        isChecking = true;
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!silent) {
          showToast('No active account found. Please sign up again.');
          if (mounted) {
            Navigator.pop(context);
          }
        }
        return;
      }

      // Refresh Firebase user information with safe timeout and force token refresh
      await user.reload().timeout(const Duration(seconds: 5));
      await user.getIdToken(true).timeout(const Duration(seconds: 5));

      final updatedUser = FirebaseAuth.instance.currentUser;

      if (updatedUser != null && updatedUser.emailVerified) {
        _verificationTimer?.cancel();
        showToast('Email verified successfully!');

        if (mounted) {
          context.read<AuthBloc>().add(const CheckAuthEvent());

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
            (route) => false,
          );
        }
      } else {
        if (!silent) {
          showToast(
            'Email is not verified yet. Please check your email or click Skip below.',
          );
        }
      }
    } on TimeoutException {
      if (!silent) {
        showToast('Verification check timed out. Please check your internet connection.');
      }
    } on FirebaseAuthException catch (e) {
      if (!silent) {
        showToast(
          e.message ?? 'Unable to check email verification.',
        );
      }
    } catch (e) {
      if (!silent) {
        showToast('Something went wrong checking verification.');
      }
    } finally {
      if (mounted && !silent) {
        setState(() {
          isChecking = false;
        });
      }
    }
  }

  // ============================================================
  // RESEND VERIFICATION EMAIL
  // ============================================================

  Future<void> resendVerificationEmail() async {
    if (isResending) return;

    setState(() {
      isResending = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        showToast('No account found.');
        return;
      }

      await user.reload().timeout(const Duration(seconds: 4));
      if (user.emailVerified) {
        showToast('Your email is already verified.');
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
        return;
      }

      await user.sendEmailVerification().timeout(const Duration(seconds: 5));

      showToast(
        'Verification email sent again. Please check your inbox and spam folder.',
      );
    } on TimeoutException {
      showToast('Request timed out. Please check your internet connection.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        showToast('Please wait a moment before requesting another email.');
      } else {
        showToast(
          e.message ?? 'Unable to send verification email.',
        );
      }
    } catch (e) {
      showToast('Something went wrong sending verification email.');
    } finally {
      if (mounted) {
        setState(() {
          isResending = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),

                        // ==================================================
                        // TOP NAVIGATION / BACK BUTTON
                        // ==================================================
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F7F7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFECECEC),
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ),

                        const Spacer(flex: 1),

                        // ==================================================
                        // EMAIL HERO ICON BADGE
                        // ==================================================
                        Container(
                          width: 104,
                          height: 104,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE8F5E9),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x2653B175),
                                blurRadius: 24,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFD4EEDD),
                              ),
                              child: const Icon(
                                Icons.mark_email_unread_rounded,
                                size: 40,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ==================================================
                        // TITLE
                        // ==================================================
                        const Text(
                          'Verify Your Email',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                            letterSpacing: -0.3,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ==================================================
                        // SUBTITLE
                        // ==================================================
                        const Text(
                          'We have sent a verification link to',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textGrey,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ==================================================
                        // EMAIL PILL BADGE
                        // ==================================================
                        if (email.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3FAF5),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0x4753B175),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.mail_outline_rounded,
                                  size: 16,
                                  color: AppColors.primaryGreen,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    email,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryGreen,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),

                        // ==================================================
                        // INSTRUCTIONS CARD
                        // ==================================================
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFEEEEEE),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: Color(0xFF888888),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Please check your inbox and tap the link to activate your account. Once verified, return here to continue.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(flex: 2),

                        // ==================================================
                        // I'VE VERIFIED BUTTON
                        // ==================================================
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                isChecking ? null : checkEmailVerification,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              disabledBackgroundColor: const Color(0xFFA7D9BA),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isChecking
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "I've Verified My Email",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ==================================================
                        // RESEND EMAIL BUTTON
                        // ==================================================
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed:
                                isResending ? null : resendVerificationEmail,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryGreen,
                              side: const BorderSide(
                                color: AppColors.primaryGreen,
                                width: 1.3,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isResending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryGreen,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.refresh_rounded,
                                        size: 20,
                                        color: AppColors.primaryGreen,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Resend Verification Email',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),



                        const SizedBox(height: 10),


                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.help_outline_rounded,
                              size: 14,
                              color: Color(0xFF999999),
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Didn't receive it? Check your spam folder.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
