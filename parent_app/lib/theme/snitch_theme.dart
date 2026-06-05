import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SnitchTheme {
  static const Color bg = Color(0xFFF4F6FB);
  static const Color primary = Color(0xFF083B66);
  static const Color accent = Color(0xFF0F5EA8);
  static const Color secondary = Color(0xFF0D7A43);
  static const Color tertiary = Color(0xFFE19A16);
  static const Color card = Colors.white;

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary, secondary: secondary, tertiary: tertiary),
        appBarTheme: const AppBarTheme(backgroundColor: primary, foregroundColor: Colors.white, elevation: 0, centerTitle: false),
        dividerColor: const Color(0xFFF1F5F9),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accent, width: 1.5)),
          labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: const Color(0xFF64748B)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        textTheme: TextTheme(
          headlineLarge: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: const Color(0xFF0B1C30)),
          headlineMedium: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF0B1C30)),
          titleLarge: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0B1C30)),
          titleMedium: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF0B1C30)),
          bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: const Color(0xFF0B1C30)),
          bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4, color: const Color(0xFF0B1C30)),
          labelLarge: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: const Color(0xFF64748B)),
        ),
      );
}
