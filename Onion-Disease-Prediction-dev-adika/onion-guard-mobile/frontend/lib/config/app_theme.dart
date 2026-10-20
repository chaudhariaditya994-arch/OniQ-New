import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color mediumGreen = Color(0xFF66BB6A);
  static const Color darkGreen = Color(0xFF388E3C);
  static const Color accentGreen = Color(0xFFA5D6A7);

  static const List<Color> gradientColors = [
    Color(0xFF81C784),
    Color(0xFF66BB6A),
    Color(0xFF4CAF50),
  ];

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: gradientColors,
  );

  static ThemeData get theme => ThemeData(
        primarySwatch: Colors.green,
        primaryColor: primaryGreen,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: primaryGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );

  static InputDecoration inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(color: Colors.white70, fontSize: 15),
      prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.white),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
    );
  }
}
