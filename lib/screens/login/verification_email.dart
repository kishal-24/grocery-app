
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../login/mobile_login_screen.dart';


class VerificationEmailScreen extends StatefulWidget {
const VerificationEmailScreen({super.key});

@override
State<VerificationEmailScreen> createState() =>
_VerificationEmailScreenState();
}

class _VerificationEmailScreenState
extends State<VerificationEmailScreen> {
bool isChecking = false;
bool isResending = false;

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

Future<void> checkEmailVerification() async {
setState(() {
isChecking = true;
});

try {
final user = FirebaseAuth.instance.currentUser;

if (user == null) {
showToast('No account found. Please sign up again.');

if (mounted) {
Navigator.pop(context);
}

return;
}

// Refresh Firebase user information
await user.reload();

final updatedUser = FirebaseAuth.instance.currentUser;

if (updatedUser != null && updatedUser.emailVerified) {
showToast('Email verified successfully!');

if (mounted) {
Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (context) => const MobileLoginScreen(),
),
);
}
} else {
showToast(
'Email is not verified yet. Please check your email.',
);
}
} on FirebaseAuthException catch (e) {
showToast(
e.message ?? 'Unable to check email verification.',
);
} catch (e) {
showToast('Something went wrong.');
} finally {
if (mounted) {
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
setState(() {
isResending = true;
});

try {
final user = FirebaseAuth.instance.currentUser;

if (user == null) {
showToast('No account found.');
return;
}

if (user.emailVerified) {
showToast('Your email is already verified.');
return;
}

await user.sendEmailVerification();

showToast(
'Verification email sent again.',
);
} on FirebaseAuthException catch (e) {
showToast(
e.message ?? 'Unable to send verification email.',
);
} catch (e) {
showToast('Something went wrong.');
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
backgroundColor: const Color(0xFFFDFDFD),

body: SafeArea(
child: Padding(
padding: const EdgeInsets.symmetric(
horizontal: 25,
),

child: Column(
children: [
// ==================================================
// TOP AREA
// ==================================================

const SizedBox(height: 35),

Align(
alignment: Alignment.centerLeft,
child: IconButton(
onPressed: () {
Navigator.pop(context);
},

padding: EdgeInsets.zero,

icon: const Icon(
Icons.arrow_back_ios_new,
size: 20,
color: Color(0xFF333333),
),
),
),

const SizedBox(height: 35),

// ==================================================
// EMAIL ICON
// ==================================================

Container(
width: 90,
height: 90,

decoration: BoxDecoration(
color: const Color(0xFFE7F7ED),
borderRadius: BorderRadius.circular(45),
),

child: const Icon(
Icons.mark_email_unread_outlined,
size: 45,
color: Color(0xFF50B879),
),
),

const SizedBox(height: 30),

// ==================================================
// TITLE
// ==================================================

const Text(
'Verify Your Email',
textAlign: TextAlign.center,

style: TextStyle(
fontSize: 25,
fontWeight: FontWeight.w700,
color: Color(0xFF111111),
),
),

const SizedBox(height: 12),

// ==================================================
// DESCRIPTION
// ==================================================

const Text(
'We have sent a verification link to',
textAlign: TextAlign.center,

style: TextStyle(
fontSize: 15,
color: Color(0xFF777777),
),
),

const SizedBox(height: 8),

// ==================================================
// EMAIL
// ==================================================

Text(
email,

textAlign: TextAlign.center,

style: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.w600,
color: Color(0xFF50B879),
),
),

const SizedBox(height: 15),

const Text(
'Please check your inbox and click the verification link. '
'After verifying your email, come back here and continue.',
textAlign: TextAlign.center,

style: TextStyle(
fontSize: 14,
height: 1.5,
color: Color(0xFF999999),
),
),

const Spacer(),

// ==================================================
// I'VE VERIFIED BUTTON
// ==================================================

SizedBox(
width: double.infinity,
height: 49,

child: ElevatedButton(
onPressed:
isChecking ? null : checkEmailVerification,

style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFF50B879),

disabledBackgroundColor:
const Color(0xFFA7D9BA),

elevation: 0,

shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(7),
),

padding: EdgeInsets.zero,
),

child: isChecking
? const SizedBox(
width: 18,
height: 18,

child: CircularProgressIndicator(
strokeWidth: 2,
color: Colors.white,
),
)
    : const Text(
"I've Verified My Email",

style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.w500,
color: Colors.white,
),
),
),
),

const SizedBox(height: 14),

// ==================================================
// RESEND EMAIL
// ==================================================

SizedBox(
width: double.infinity,
height: 49,

child: OutlinedButton(
onPressed:
isResending ? null : resendVerificationEmail,

style: OutlinedButton.styleFrom(
foregroundColor: const Color(0xFF50B879),

side: const BorderSide(
color: Color(0xFF50B879),
),

shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(7),
),
),

child: isResending
? const SizedBox(
width: 18,
height: 18,

child: CircularProgressIndicator(
strokeWidth: 2,

color: Color(0xFF50B879),
),
)
    : const Text(
'Resend Verification Email',

style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.w500,
),
),
),
),

const SizedBox(height: 25),

// ==================================================
// BOTTOM TEXT
// ==================================================

const Text(
'Didn\'t receive the email? Check your spam folder.',
textAlign: TextAlign.center,

style: TextStyle(
fontSize: 13,
color: Color(0xFF999999),
),
),

const SizedBox(height: 20),
],
),
),
),
);
}
}
