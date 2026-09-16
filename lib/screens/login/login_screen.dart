import 'package:flutter/material.dart';
import 'package:grocery_app/screens/location/location_screen.dart';

import 'package:grocery_app/screens/login/mobile_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController =
  TextEditingController();



  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }



  void loginWithGoogle() {

  }

  void loginWithFacebook() {

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [


            Expanded(
              flex: 5,
              child: SizedBox(
                width: double.infinity,
                child: Image.asset(
                  'assets/Mask Group.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),


            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 12),


                    const Text(
                      'Get your groceries\nwith nectar',
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.w600,
                        height: 1.7,
                        color: Color(0xFF181725),
                      ),
                    ),

                    const SizedBox(height: 22),


                    SizedBox(
                      width: double.infinity,
                      height: 70,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LocationScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          elevation: 0,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(9),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [

                            const Icon(
                              Icons.mail,
                            ),

                            const SizedBox(width: 15,),

                            const Text(
                              'Continue with email id',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight:
                                FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),


                    const Divider(
                      height: 4,
                      color: Color(0xFFE2E2E2),
                    ),

                    const SizedBox(height: 15),


                    const Center(
                      child: Text(
                        'Or connect with social media',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF7C7C7C),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),


                    SizedBox(
                      width: double.infinity,
                      height: 70,
                      child: ElevatedButton(
                        onPressed: loginWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFF5383EC),
                          elevation: 0,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(9),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [

                            const Text(
                              'G',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                            const SizedBox(width: 15),

                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight:
                                FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 70,
                      child: ElevatedButton(
                        onPressed: loginWithFacebook,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFF4969A9),
                          elevation: 0,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(9),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [

                            const Text(
                              'f',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                            const SizedBox(width: 18),

                            const Text(
                              'Continue with Facebook',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight:
                                FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Phonelog extends StatelessWidget {
  const Phonelog({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Phone Log Screen')),
    );
  }
}