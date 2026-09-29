import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_panel_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for Web or current platform
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const FreshBasketAdminApp());
}

class FreshBasketAdminApp extends StatelessWidget {
  const FreshBasketAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreshBasket Admin Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primaryGreen,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          primary: AppColors.primaryGreen,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        fontFamily: 'SF Pro Display',
      ),
      home: const AdminAuthGate(),
    );
  }
}

/// Authentication and Role Gate for the Admin Portal
class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF3F5F7),
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const AdminLoginScreen();
        }

        // User is authenticated via Firebase Auth; verify 'admin' role in Firestore
        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userDocSnapshot) {
            if (userDocSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFFF3F5F7),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primaryGreen),
                      SizedBox(height: 16),
                      Text(
                        'Verifying administrator credentials...',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (userDocSnapshot.hasError || !userDocSnapshot.hasData || !userDocSnapshot.data!.exists) {
              FirebaseAuth.instance.signOut();
              return const AdminLoginScreen(
                initialErrorMessage: 'Access Denied: Could not verify user profile in database.',
              );
            }

            final userData = userDocSnapshot.data!.data();
            final role = userData?['role'] as String?;

            if (role == 'admin') {
              return const AdminPanelScreen();
            } else {
              // Reject non-admin customer account
              FirebaseAuth.instance.signOut();
              return AdminLoginScreen(
                initialErrorMessage:
                    'Access Denied: Account role is "$role". Admin privileges are required.',
              );
            }
          },
        );
      },
    );
  }
}
