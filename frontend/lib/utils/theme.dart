import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF107C41); // Hijau gelap
  static const Color lightGreen = Color(
    0xFFE8F5E9,
  ); // Hijau sangat muda (TAMBAHAN)
  static const Color accentOrange = Color(0xFFFF7A00); // Oranye cerah
  static const Color bgColor = Color(0xFFF5F7FA);
  static const Color textDark = Color(0xFF1E1E1E); // Hitam pekat
  static const Color textGrey = Color(0xFF757575);
  static const Color teal = Color(0xFF00897B);
  static const Color lightBlue = Color(0xFFE3F2FD);

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: bgColor,
      primaryColor: primaryGreen,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryGreen),

      fontFamily: 'Segoe UI',

      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: textDark,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        titleMedium: TextStyle(
          color: textDark,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(color: textDark, fontSize: 16),
        bodyMedium: TextStyle(color: textGrey, fontSize: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: textDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 20,
        ),
        labelStyle: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
      ),
    );
  }
}
