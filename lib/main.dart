import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'views/login_screen.dart';
import 'views/home_screen.dart';
import 'views/splash_screen.dart';
import 'services/theme_service.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeNotifierProvider);
    
    Color getBackgroundColor() {
      switch (currentTheme) {
        case AppThemeMode.dark:
          return Colors.black;
        case AppThemeMode.orange:
          return ThemeColors.orangeBackground;
        case AppThemeMode.green:
          return ThemeColors.greenBackground;
      }
    }

    final backgroundColor = getBackgroundColor();
    final bool isDarkTheme = currentTheme == AppThemeMode.dark;
    
    return MaterialApp(
      title: '小白单词',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: backgroundColor,
          foregroundColor: isDarkTheme ? Colors.white : ThemeColors.blackText,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
