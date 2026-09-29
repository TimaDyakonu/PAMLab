import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/mock_data.dart';
import 'data/mock_item_repository.dart';
import 'data/mock_network.dart';
import 'data/mock_reservation_repository.dart';
import 'data/user.dart';
import 'models/favorites_model.dart';
import 'models/items_model.dart';
import 'models/reservations_model.dart';
import 'router.dart';

// Корень композиции: ЗДЕСЬ (и только здесь) выбирается источник данных.
// На L5 вместо mock-репозиториев появятся http-варианты — и всё.
void main() {
  final network = MockNetwork();
  final itemRepository = MockItemRepository(network);
  final reservationRepository = MockReservationRepository(network);

  runApp(
    MultiProvider(
      providers: [
        // леса демонстрации аварии (профиль) — исчезают на L5
        Provider<MockNetwork>.value(value: network),
        // «вошедший» пользователь; вход на L4 — по-прежнему локальная валидация
        Provider<User>.value(value: mockCurrentUser),
        ChangeNotifierProvider(
          create: (_) => ItemsModel(itemRepository)..load(), // DI + старт
        ),
        ChangeNotifierProvider(
          create: (_) => ReservationsModel(reservationRepository)..load(),
        ),
        ChangeNotifierProvider(create: (_) => FavoritesModel()),
      ],
      child: const MyApp(),
    ),
  );
}

const _seedColor = Color(0xFF4A7C59);
const _themeMode = ThemeMode.system;

ThemeData _buildTheme(Brightness brightness) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w600),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Second Hand Market',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: _themeMode,
      routerConfig: router,
    );
  }
}
