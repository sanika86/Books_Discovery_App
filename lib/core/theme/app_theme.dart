import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 🎨 Colors
  static const Color primaryColor = Color(0xFF1565C0); // Blue
  static const Color accentColor = Color(0xFF42A5F5);  // Light Blue
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light grey
  static const Color textColor = Color(0xFF212121); // Dark text

  // 🔠 Text Styles
  static TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.poppins(
        fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
    headlineMedium: GoogleFonts.poppins(
        fontSize: 24, fontWeight: FontWeight.w600, color: textColor),
    titleMedium: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w500, color: textColor),
    bodyMedium: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.normal, color: textColor),
    labelLarge: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
  );

  // 🎭 App ThemeData
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: primaryColor,
      secondary: accentColor,
    ),
    textTheme: textTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accentColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: const BorderSide(color: primaryColor),
      ),
    ),
  );
}
