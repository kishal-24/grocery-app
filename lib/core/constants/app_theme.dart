import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    scaffoldBackgroundColor: Colors.white,

    textTheme: GoogleFonts.poppinsTextTheme(),

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF53B175),
    ),
  );
}