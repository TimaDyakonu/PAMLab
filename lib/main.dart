// main.dart — MaterialApp + тема + стартовый экран
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() => runApp(const MyApp());

// Семя палитры — приглушённый лесной зелёный: цвет осознанного
// потребления и вторичного использования вещей (эко-тематика секонд-хенда).
// ColorScheme.fromSeed выводит из него все роли (primary, surface, …).
const _seedColor = Color(0xFF4A7C59);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Second Hand Market',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
        // базовая типографика: точечные подстройки, остальное по умолчанию
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor, // то же семя…
          brightness: Brightness.dark, // …ночная палитра
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      themeMode: ThemeMode.system, // следует настройке телефона
      home: const LoginScreen(),
    );
  }
}
