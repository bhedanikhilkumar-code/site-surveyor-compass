import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _themeKey = 'theme_mode';
  static const String _primaryColorKey = 'primary_color';

  ThemeMode _themeMode = ThemeMode.dark;
  Color _primaryColor = Colors.blueAccent;

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

  ThemeData getThemeData({required BuildContext context}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: _themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
      ),
    );
  }
}
