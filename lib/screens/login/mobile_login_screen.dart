import 'package:flutter/material.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() =>
      _MobileLoginScreenState();
}

class _MobileLoginScreenState
    extends State<MobileLoginScreen> {

  final TextEditingController emailController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  bool hidePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                const SizedBox(height: 35),

                // LOGO
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    width: 45,
                    height: 45,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 38),

                // TITLE
                const Text(
                  'Loging',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Enter your email and password',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 30),

                // EMAIL
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 6),

                TextField(
                  controller: emailController,
                  keyboardType:
                  TextInputType.emailAddress,

                  style: const TextStyle(
                    fontSize: 11,
                  ),

                  decoration: const InputDecoration(
                    hintText: 'Enter your email',

                    hintStyle: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),

                    isDense: true,

                    contentPadding:
                    EdgeInsets.symmetric(
                      vertical: 8,
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
                        color: Color(0xFF53B175),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 19),

                // PASSWORD
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 6),

                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,

                  style: const TextStyle(
                    fontSize: 11,
                  ),

                  decoration: InputDecoration(
                    hintText: 'Enter your password',

                    hintStyle: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),

                    isDense: true,

                    contentPadding:
                    const EdgeInsets.symmetric(
                      vertical: 8,
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
                        color: Color(0xFF53B175),
                        width: 1.5,
                      ),
                    ),

                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hidePassword =
                          !hidePassword;
                        });
                      },

                      icon: Icon(
                        hidePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 15,
                        color: Colors.grey,
                      ),
                    ),

                    suffixIconConstraints:
                    const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                  ),
                ),

                // FORGOT PASSWORD
                Align(
                  alignment: Alignment.centerRight,

                  child: TextButton(
                    onPressed: () {
                      // Forgot password
                    },

                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize:
                      MaterialTapTargetSize
                          .shrinkWrap,
                    ),

                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 48,

                  child: ElevatedButton(
                    onPressed: () {
                      // AuthBloc will be connected here
                    },

                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF53B175),

                      foregroundColor: Colors.white,

                      elevation: 0,

                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(9),
                      ),
                    ),

                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // SIGNUP
                Center(
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,

                    children: [

                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 9,
                        ),
                      ),

                      GestureDetector(
                        onTap: () {
                          // Signup screen
                        },

                        child: const Text(
                          'Signup',
                          style: TextStyle(
                            fontSize: 9,
                            color:
                            Color(0xFF53B175),
                            fontWeight:
                            FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}