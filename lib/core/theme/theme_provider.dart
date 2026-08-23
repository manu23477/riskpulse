import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F172A),
        primary: const Color(0xFF0D9488),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF22D3EE),
        secondary: Color(0xFF0D9488),
        surface: Color(0xFF161E31),
        error: Color(0xFFF43F5E),
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: Color(0xFFE2E8F0),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF0A0F1E),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF161E31),
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFFE2E8F0)),
        titleTextStyle: TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF161E31),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
