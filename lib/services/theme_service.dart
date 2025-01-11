import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_service.g.dart';

enum AppThemeMode {
  dark,
  orange,
  green,
}

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  static const String _themeKey = 'themeMode';

  @override
  AppThemeMode build() {
    _loadTheme();
    return AppThemeMode.dark;
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 0;
      state = AppThemeMode.values[themeIndex];
    } catch (e) {
      print('Error loading theme: $e');
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, mode.index);
      state = mode;
    } catch (e) {
      print('Error setting theme: $e');
    }
  }
}

class ThemeColors {
  // 橙色主题颜色
  static const orangeBackground = Color(0xFFF7EEDD);
  static const orangeCard = Color(0xFFFF7F50);
  static const orangeDefaultCard = Color(0xFFEDE4D3);
  
  // 绿色主题颜色
  static const greenBackground = Color(0xFFF2EFE9);
  static const greenCard = Color(0xFF00A896);
  static const greenDefaultCard = Color(0xFFE8E5DF);
  
  // 通用颜色
  static const blackText = Color(0xFF000000);
} 