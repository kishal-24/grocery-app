import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grocery_app/screens/login/mobile_login_screen.dart';
import 'package:grocery_app/screens/login/verification_email.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {

  final TextEditingController usernameController =
  TextEditingController();

  final TextEditingController emailController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();


  bool obscurePassword = true;



  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // TOAST
  // ============================================================

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  // ============================================================
  // SIGNUP
  // ============================================================

  void signup() {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // ----------------------------------------------------------
    // USERNAME VALIDATION
    // ----------------------------------------------------------

    if (username.isEmpty) {
      showToast('Please enter your username');
      return;
    }

    // ----------------------------------------------------------
    // EMAIL VALIDATION
    // ----------------------------------------------------------

    if (email.isEmpty) {
      showToast('Please enter your email');
      return;
    }

    // ----------------------------------------------------------
    // PASSWORD VALIDATION
    // ----------------------------------------------------------

    if (password.isEmpty) {
      showToast('Please enter your password');
      return;
    }

    if (password.length < 6) {
      showToast('Password must be at least 6 characters');
      return;
    }

    // ----------------------------------------------------------
    // SEND SIGNUP EVENT TO AUTH BLOC
    // ----------------------------------------------------------

    context.read<AuthBloc>().add(
      SignupEvent(
        email: email,
        password: password,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),

      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            // ==================================================
            // VERIFICATION EMAIL SENT
            // ==================================================

            if (state.status == AuthStatus.verificationSent) {
              showToast(
                'Verification email sent. Please check your email.',
              );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const VerificationEmailScreen(),
                ),
              );
            }



            if (state.status == AuthStatus.failure) {
              showToast(
                state.errorMessage ?? 'Signup failed',
              );
            }
          },

          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),

                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),

                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        // ==================================================
                        // TOP LOGO AREA
                        // ==================================================

                        SizedBox(
                          height: 82,
                          child: Center(
                            child: Image.asset(
                              'assets/logo.png',
                              width: 62,
                              height: 62,
                              fit: BoxFit.contain,

                              errorBuilder:
                                  (context, error, stackTrace) {
                                return const Icon(
                                  Icons.eco,
                                  size: 58,
                                  color: Color(0xFF50B879),
                                );
                              },
                            ),
                          ),
                        ),

                        // ==================================================
                        // SIGN UP TITLE
                        // ==================================================

                        const SizedBox(height: 17),

                        const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111111),
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'Enter your credentials to continue',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8A8A8A),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ==================================================
                        // USERNAME LABEL
                        // ==================================================

                        const Text(
                          'Username',
                          style: TextStyle(
                            fontSize: 25,
                            color: Color(0xFF777777),
                          ),
                        ),

                        const SizedBox(height: 5),

                        // ==================================================
                        // USERNAME FIELD
                        // ==================================================

                        TextField(
                          controller: usernameController,

                          textInputAction:
                          TextInputAction.next,

                          style: const TextStyle(
                            fontSize: 20,
                            color: Color(0xFF333333),
                          ),

                          decoration:
                          const InputDecoration(
                            hintText:
                            'Enter your username',

                            hintStyle: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF444444),
                            ),

                            isDense: true,

                            contentPadding:
                            EdgeInsets.only(
                              left: 0,
                              right: 0,
                              bottom: 7,
                            ),

                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFFE5E5E5),
                              ),
                            ),

                            enabledBorder:
                            UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFFE5E5E5),
                              ),
                            ),

                            focusedBorder:
                            UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFF50B879),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ==================================================
                        // EMAIL LABEL
                        // ==================================================

                        const Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 25,
                            color: Color(0xFF777777),
                          ),
                        ),

                        const SizedBox(height: 5),

                        // ==================================================
                        // EMAIL FIELD
                        // ==================================================

                        TextField(
                          controller: emailController,

                          keyboardType:
                          TextInputType.emailAddress,

                          textInputAction:
                          TextInputAction.next,

                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF333333),
                          ),

                          decoration:
                          const InputDecoration(
                            hintText:
                            'Enter your email',

                            hintStyle: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF444444),
                            ),

                            isDense: true,

                            contentPadding:
                            EdgeInsets.only(
                              left: 0,
                              right: 25,
                              bottom: 7,
                            ),

                            suffixIcon:
                            Icon(
                              Icons.check,
                              size: 14,
                              color: Color(0xFF50B879),
                            ),

                            suffixIconConstraints:
                            BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),

                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFFE5E5E5),
                              ),
                            ),

                            enabledBorder:
                            UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFFE5E5E5),
                              ),
                            ),

                            focusedBorder:
                            UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFF50B879),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ==================================================
                        // PASSWORD LABEL
                        // ==================================================

                        const Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 25,
                            color: Color(0xFF777777),
                          ),
                        ),

                        const SizedBox(height: 5),

                        // ==================================================
                        // PASSWORD FIELD
                        // ==================================================

                        TextField(
                          controller: passwordController,

                          obscureText: obscurePassword,

                          textInputAction:
                          TextInputAction.done,

                          onSubmitted: (_) {
                            signup();
                          },

                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF333333),
                          ),

                          decoration:
                          InputDecoration(
                            hintText:
                            'Enter your password',

                            hintStyle:
                            const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF444444),
                            ),

                            isDense: true,

                            contentPadding:
                            const EdgeInsets.only(
                              left: 0,
                              right: 25,
                              bottom: 7,
                            ),

                            suffixIcon:
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  obscurePassword =
                                  !obscurePassword;
                                });
                              },

                              padding:
                              EdgeInsets.zero,

                              constraints:
                              const BoxConstraints(
                                minWidth: 25,
                                minHeight: 25,
                              ),

                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,

                                size: 14,

                                color:
                                const Color(
                                  0xFF777777,
                                ),
                              ),
                            ),

                            border:
                            const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFFE5E5E5),
                              ),
                            ),

                            enabledBorder:
                            const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFFE5E5E5),
                              ),
                            ),

                            focusedBorder:
                            const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFF50B879),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),


                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF999999),
                              height: 1.4,
                            ),

                            children: [
                              TextSpan(
                                text:
                                'By continuing you agree to our ',
                              ),

                              TextSpan(
                                text:
                                'Terms of Service',
                                style: TextStyle(
                                  color:
                                  Color(0xFF50B879),
                                ),
                              ),

                              TextSpan(
                                text: '\nand ',
                              ),

                              TextSpan(
                                text:
                                'Privacy Policy.',
                                style: TextStyle(
                                  color:
                                  Color(0xFF50B879),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),


                        BlocBuilder<AuthBloc, AuthState>(
                          builder:
                              (context, state) {
                            final isLoading =
                                state.status ==
                                    AuthStatus.loading;

                            return SizedBox(
                              width: double.infinity,
                              height: 49,


                              child: ElevatedButton(
                                onPressed: isLoading ? null : signup,

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF50B879),
                                  disabledBackgroundColor: const Color(0xFFA7D9BA),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),

                                child: isLoading
                                    ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),




                        const SizedBox(height: 12),

                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 15,
                                color:
                                Color(0xFF333333),
                              ),

                              children: [
                                const TextSpan(
                                  text:
                                  'Already have an account? ',
                                ),

                                WidgetSpan(
                                  child:
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(
                                        context,
                                      );
                                    },

                                    child: const Text(
                                      'Login',
                                      style:
                                      TextStyle(
                                        fontSize: 15,
                                        color:
                                        Color(
                                          0xFF50B879,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}