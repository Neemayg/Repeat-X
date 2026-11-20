import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ink and paper: navy app chrome, cream for anything that becomes an exam.
/// Heat is the only strong colour and always means "how often it was asked".
class RX {
  static const ink = Color(0xFF0E121C);
  static const surface = Color(0xFF161B28);
  static const raised = Color(0xFF1C2232);
  static const line = Color(0xFF29303F);
  static const fg = Color(0xFFECEFF5);
  static const fg2 = Color(0xFFA3ACBF);
  static const fg3 = Color(0xFF7C869C);
  static const paper = Color(0xFFF4EFE4);
  static const paperInk = Color(0xFF1B1815);
  static const accent = Color(0xFFE6D8B5);
  static const ok = Color(0xFF7FB88A);
  static const warn = Color(0xFFE0A060);

  /// 1× grey · 2× mauve · 3× amber · 4× orange · 5×+ coral.
  static Color heat(int count) => switch (count) {
        <= 1 => const Color(0xFF59627A),
        2 => const Color(0xFF8A8697),
        3 => const Color(0xFFC08A45),
        4 => const Color(0xFFD2723A),
        _ => const Color(0xFFDD5540),
      };

  static TextStyle serif(double size, {FontWeight weight = FontWeight.w500, Color? color}) =>
      GoogleFonts.newsreader(fontSize: size, fontWeight: weight, color: color ?? fg, height: 1.15);

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ink,
      colorScheme: const ColorScheme.dark(
        surface: ink,
        primary: paper,
        onPrimary: paperInk,
        secondary: accent,
        outline: line,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: fg, displayColor: fg),
      appBarTheme: const AppBarTheme(backgroundColor: ink, elevation: 0, foregroundColor: fg2),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: paper,
          foregroundColor: paperInk,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: line),
        ),
      ),
    );
  }
}
