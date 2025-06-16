import 'package:flutter/material.dart';

/// A provider class for managing the app's theme with Notion-inspired aesthetics
class ThemeProvider extends ChangeNotifier {
  // Notion-inspired color palette
  static const Color notionBlack = Color(0xFF191919);
  static const Color notionGray = Color(0xFF787774);
  static const Color notionLightGray = Color(0xFFEBEBEA);
  static const Color notionWhite = Color(0xFFFAFAFA);
  static const Color notionBlue = Color(0xFF2383E2);
  static const Color notionFaintBlue = Color(0xFFE7F3FE);
  static const Color notionDarkGray = Color(0xFF2D2D2D);

  // Theme mode: light or dark
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  // Toggle between light and dark themes
  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Light theme - Notion inspired
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: notionBlack,
        onPrimary: notionWhite,
        secondary: notionBlue,
        onSecondary: notionWhite,
        tertiary: notionGray,
        surface: notionWhite,
        background: notionWhite,
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: notionWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: notionWhite,
        foregroundColor: notionBlack,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: notionBlack,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          fontFamily: 'Inter',
        ),
      ),
      cardTheme: CardTheme(
        color: notionWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: notionBlack,
          foregroundColor: notionWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          elevation: 0,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.selected)) {
              return notionLightGray;
            }
            return notionWhite;
          }),
          foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.selected)) {
              return notionBlack;
            }
            return notionGray;
          }),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          ),
          side: MaterialStatePropertyAll(
            BorderSide(color: notionLightGray, width: 1),
          ),
          padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: notionBlack,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          fontFamily: 'Inter',
        ),
        titleLarge: TextStyle(
          color: notionBlack,
          fontWeight: FontWeight.w600,
          fontSize: 16,
          fontFamily: 'Inter',
        ),
        titleMedium: TextStyle(
          color: notionBlack,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          fontFamily: 'Inter',
        ),
        bodyLarge: TextStyle(
          color: notionBlack,
          fontWeight: FontWeight.normal,
          fontSize: 14,
          fontFamily: 'Inter',
        ),
        bodyMedium: TextStyle(
          color: notionGray,
          fontWeight: FontWeight.normal,
          fontSize: 14,
          fontFamily: 'Inter',
        ),
      ),
      iconTheme: const IconThemeData(color: notionGray, size: 20),
    );
  }

  // Dark theme - Notion inspired
  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: notionWhite,
        onPrimary: notionBlack,
        secondary: notionBlue,
        onSecondary: notionWhite,
        tertiary: notionLightGray,
        surface: const Color(0xFF2D2D2D),
        background: notionBlack,
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: notionBlack,
      appBarTheme: const AppBarTheme(
        backgroundColor: notionBlack,
        foregroundColor: notionWhite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: notionWhite,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          fontFamily: 'Inter',
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF2D2D2D),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: const BorderSide(color: Color(0xFF404040), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: notionWhite,
          foregroundColor: notionBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          elevation: 0,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF404040);
            }
            return const Color(0xFF2D2D2D);
          }),
          foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.selected)) {
              return notionWhite;
            }
            return notionLightGray;
          }),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          ),
          side: const MaterialStatePropertyAll(
            BorderSide(color: Color(0xFF404040), width: 1),
          ),
          padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF404040),
        thickness: 1,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: notionWhite,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          fontFamily: 'Inter',
        ),
        titleLarge: TextStyle(
          color: notionWhite,
          fontWeight: FontWeight.w600,
          fontSize: 16,
          fontFamily: 'Inter',
        ),
        titleMedium: TextStyle(
          color: notionWhite,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          fontFamily: 'Inter',
        ),
        bodyLarge: TextStyle(
          color: notionWhite,
          fontWeight: FontWeight.normal,
          fontSize: 14,
          fontFamily: 'Inter',
        ),
        bodyMedium: TextStyle(
          color: notionLightGray,
          fontWeight: FontWeight.normal,
          fontSize: 14,
          fontFamily: 'Inter',
        ),
      ),
      iconTheme: const IconThemeData(color: notionLightGray, size: 20),
    );
  }
}
