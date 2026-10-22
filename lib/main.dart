import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'data/api_client.dart';
import 'data/api_config.dart';
import 'data/auth_api.dart';
import 'data/file_api.dart';
import 'data/http_item_repository.dart';
import 'data/http_reservation_repository.dart';
import 'data/item_repository.dart';
import 'data/reservation_repository.dart';
import 'data/result.dart';
import 'data/token_store.dart';
import 'models/favorites_model.dart';
import 'models/items_model.dart';
import 'models/reservations_model.dart';
import 'models/session_model.dart';
import 'router.dart';

/// Адрес сервера. Эмулятор Android не знает «localhost»: сервер на ноутбуке для
/// него это 10.0.2.2. На десктопе или телефоне адрес задаётся при запуске:
/// flutter run --dart-define=API_BASE=http://192.168.0.10:8765
const apiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://10.0.2.2:8765',
);

// Корень композиции: ЗДЕСЬ (и только здесь) меняется источник данных.
// На L4 тут стоял mock, на L5 стоят http-репозитории, а экраны и модели
// остались теми же.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // prefs нужны до runApp

  final tokens = TokenStore();
  final session = SessionModel();
  var started = false;

  final api = ApiClient(
    apiBase,
    tokens,
    onUnauthorized: () {
      if (!started) return;
      router.go('/login'); // 401: токен уже стёрт, возвращаемся на вход
      session.signOut();
    },
  );
  final auth = AuthApi(api, tokens);

  // Запуск решает токен: пока он жив, на login не возвращаемся.
  if (await tokens.read() != null) {
    final me = await auth.me();
    if (me case Ok(:final value)) session.signIn(value);
  }
  router = buildRouter(session.isSignedIn ? '/feed' : '/login');
  started = true;

  runApp(
    MultiProvider(
      providers: appProviders(
        config: const ApiConfig(apiBase),
        auth: auth,
        files: FileApi(api, apiBase),
        session: session,
        items: HttpItemRepository(api),
        reservations: HttpReservationRepository(api),
      ),
      child: const MyApp(),
    ),
  );
}

/// Дерево провайдеров приложения. Модели данных привязаны к вошедшему
/// пользователю: при входе другого человека (или выходе) создаются заново,
/// чтобы данные прошлого пользователя не просвечивали.
List<SingleChildWidget> appProviders({
  required ApiConfig config,
  required AuthApi auth,
  required FileApi files,
  required SessionModel session,
  required ItemRepository items,
  required ReservationRepository reservations,
}) {
  return [
    Provider<ApiConfig>.value(value: config),
    Provider<AuthApi>.value(value: auth),
    Provider<FileApi>.value(value: files),
    ChangeNotifierProvider<SessionModel>.value(value: session),
    ChangeNotifierProxyProvider<SessionModel, ItemsModel>(
      create: (_) => ItemsModel(items),
      update: (_, session, previous) {
        if (previous != null && previous.userId == session.userId) {
          return previous;
        }
        final model = ItemsModel(items, userId: session.userId);
        if (session.isSignedIn) {
          model.load(); // DI + старт, как на L4
          model.loadMine();
        }
        return model;
      },
    ),
    ChangeNotifierProxyProvider<SessionModel, ReservationsModel>(
      create: (_) => ReservationsModel(reservations),
      update: (context, session, previous) {
        if (previous != null && previous.userId == session.userId) {
          return previous;
        }
        final model = ReservationsModel(
          reservations,
          userId: session.userId,
          onItemChanged: (item) => context.read<ItemsModel>().apply(item),
        );
        if (session.isSignedIn) model.load();
        return model;
      },
    ),
    ChangeNotifierProxyProvider<SessionModel, FavoritesModel>(
      create: (_) => FavoritesModel(),
      update: (_, session, previous) {
        if (previous != null && previous.userId == session.userId) {
          return previous;
        }
        return FavoritesModel(userId: session.userId);
      },
    ),
  ];
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
