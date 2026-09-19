// main.dart — MaterialApp + тема + стартовый экран.
// Вся тема приложения задаётся здесь и только здесь: экраны берут цвета
// из ролей Theme.of(context).colorScheme и ничего не зашивают в код.
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() => runApp(const MyApp());

// ---------------------------------------------------------------------------
// Единственное место настройки темы
// ---------------------------------------------------------------------------

// Семя палитры — приглушённый лесной зелёный: цвет осознанного
// потребления и вторичного использования вещей (эко-тематика секонд-хенда).
// ColorScheme.fromSeed выводит из него все роли (primary, surface, …).
const _seedColor = Color(0xFF4A7C59);

// Какой режим использовать: system — по настройке телефона,
// light — всегда светлая, dark — всегда тёмная.
const _themeMode = ThemeMode.system;

/// Строит тему из одного семени: светлую или тёмную — по яркости.
ThemeData _buildTheme(Brightness brightness) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    ),
    // базовая типографика: точечные подстройки, остальное по умолчанию
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w600),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Second Hand Market',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: _themeMode,
      home: const LoginScreen(),
    );
  }
}
