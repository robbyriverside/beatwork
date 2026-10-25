import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette
  static const Color background = Color(0xFFF6F4EF);
  static const Color surface = Color(0xFFFFFEFA);
  static const Color surfaceElevated = Color(0xFFF5EBD3);
  static const Color surfaceLighter = Color(0xFFE7E4DC);
  static const Color border = Color(0xFFDDD9CF);
  static const Color borderHighlight = Color(0xFFBDB6A8);

  // Screenplay & Cinema Accents
  static const Color goldAccent = Color(0xFFD59A32);
  static const Color goldLight = Color(0xFF91600D);
  static const Color cyanAccent = Color(0xFF087E8B);
  static const Color emeraldAccent = Color(0xFF16805D);
  static const Color crimsonAccent = Color(0xFFBF4052);
  static const Color purpleAccent = Color(0xFF7355A3);

  // Text Colors
  static const Color textPrimary = Color(0xFF282A27);
  static const Color textSecondary = Color(0xFF62645F);
  static const Color textMuted = Color(0xFF85867F);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: 'Avenir Next',
      scaffoldBackgroundColor: background,
      primaryColor: goldAccent,
      cardColor: surface,
      dividerColor: border,
      colorScheme: const ColorScheme.light(
        primary: goldAccent,
        secondary: cyanAccent,
        surface: surface,
        error: crimsonAccent,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderHighlight, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: goldAccent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: goldAccent,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderHighlight),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontSize: 13),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surfaceLighter,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderHighlight),
        ),
        textStyle: const TextStyle(color: textPrimary, fontSize: 12),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(borderHighlight),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(6),
      ),
    );
  }

  // Screenplay Couriers
  static const TextStyle screenplaySlugline = TextStyle(
    fontFamily: 'Courier',
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle screenplayAction = TextStyle(
    fontFamily: 'Courier',
    fontSize: 13.5,
    height: 1.45,
    color: textPrimary,
  );

  static const TextStyle screenplayCharacter = TextStyle(
    fontFamily: 'Courier',
    fontSize: 13.5,
    fontWeight: FontWeight.bold,
    color: goldLight,
    letterSpacing: 0.8,
  );

  static const TextStyle screenplayDialogue = TextStyle(
    fontFamily: 'Courier',
    fontSize: 13.5,
    height: 1.4,
    color: textPrimary,
  );
}
