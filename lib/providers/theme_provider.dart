import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../utils/app_constants.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _themeKey = 'theme_mode';
  static const String _primaryColorKey = 'primary_color';

  ThemeMode _themeMode = ThemeMode.dark;
  Color _primaryColor = const Color(0xFF1E40AF); // Premium blue

  // Premium Colors
  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color neutralSlate = Color(0xFF64748B);
  static const Color neutralLight = Color(0xFF94A3B8);

  // Text Theme
  static final TextTheme textTheme = TextTheme(
    headlineLarge: GoogleFonts.plusJakartaSans(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -0.5,
    ),
    headlineMedium: GoogleFonts.plusJakartaSans(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.33,
      letterSpacing: -0.25,
    ),
    bodyLarge: GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodySmall: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      color: neutralSlate,
    ),
  );

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  Color get primaryColor => _primaryColor;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final box = await Hive.openBox(_boxName);
    final saved = box.get(_themeKey) as String?;
    final savedColor = box.get(_primaryColorKey) as int?;
    
    if (saved == 'light') {
      _themeMode = ThemeMode.light;
    } else if (saved == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.dark;
    }
    
    if (savedColor != null) {
      _primaryColor = Color(savedColor);
    }
    
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_themeKey, _themeMode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    final modeStr = mode == ThemeMode.dark ? 'dark' : mode == ThemeMode.light ? 'light' : 'system';
    await box.put(_themeKey, modeStr);
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_primaryColorKey, color.value);
  }

  ThemeData getLightTheme() {
    final colorScheme = const ColorScheme.light(
      primary: primaryBlue,
      secondary: secondaryBlue,
      tertiary: accentAmber,
      surface: Colors.white,
      onSurface: neutralSlate,
      outline: neutralLight,
    );

    final shadowColor = Colors.black.withOpacity(0.1);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme.apply(
        bodyColor: neutralSlate,
        displayColor: neutralSlate,
      ),
      shadowColor: shadowColor,
      cardTheme: CardTheme(
        elevation: 3,
        shadowColor: shadowColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white.withOpacity(0.95),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neutralLight),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.all(AppSpacing.sm),
      ),
    );
  }

  ThemeData getDarkTheme() {
    final colorScheme = const ColorScheme.dark(
      primary: secondaryBlue,
      secondary: primaryBlue,
      tertiary: accentAmber,
      surface: Color(0xFF0F172A),
      onSurface: Color(0xFFF1F5F9),
      outline: neutralLight,
    );

    final shadowColor = Colors.black.withOpacity(0.3);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme.apply(
        bodyColor: const Color(0xFFF1F5F9),
        displayColor: const Color(0xFFF1F5F9),
      ),
      shadowColor: shadowColor,
      cardTheme: CardTheme(
        elevation: 3,
        shadowColor: shadowColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xFF1E293B).withOpacity(0.9),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neutralLight),
        ),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: EdgeInsets.all(AppSpacing.sm),
      ),
    );
  }

  ThemeData getThemeData({required BuildContext context}) {
    return _themeMode == ThemeMode.dark ? getDarkTheme() : getLightTheme();
  }
}
