import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:second_hand_market/data/api_client.dart';
import 'package:second_hand_market/data/api_config.dart';
import 'package:second_hand_market/data/file_api.dart';
import 'package:second_hand_market/data/http_item_repository.dart';
import 'package:second_hand_market/data/item.dart';
import 'package:second_hand_market/data/http_reservation_repository.dart';
import 'package:second_hand_market/data/token_store.dart';
import 'package:second_hand_market/main.dart';
import 'package:second_hand_market/models/session_model.dart';
import 'package:second_hand_market/router.dart';
import 'package:second_hand_market/screens/login_screen.dart';
import 'package:second_hand_market/screens/my_purchases_screen.dart';

import 'support/fake_data.dart';
import 'support/fake_repositories.dart';
import 'support/test_app.dart';

Future<void> pumpApp(
  WidgetTester tester,
  TestApp app, {
  bool signedIn = true,
}) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(app.build(signedIn: signedIn));
  await tester.pumpAndSettle();
}

Future<void> fillLogin(WidgetTester tester,
    {String email = 'admin@secondhand.md', String password = 'secret123'}) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), email);
  await tester.enterText(find.widgetWithText(TextFormField, 'Пароль'), password);
}

void main() {
  group('вход и регистрация', () {
    testWidgets('приложение стартует на экране входа', (tester) async {
      await pumpApp(tester, TestApp(), signedIn: false);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Second Hand Market'), findsWidgets);
    });

    testWidgets('пустая форма: валидаторы L3 на месте, сервер не вызывается',
        (tester) async {
      final app = TestApp();
      await pumpApp(tester, app, signedIn: false);

      await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
      await tester.pumpAndSettle();

      expect(find.text('Введите e-mail'), findsOneWidget);
      expect(find.text('Введите пароль'), findsOneWidget);
      expect(app.lastAuthBody, isNull);
    });

    testWidgets('верный вход: токен в prefs, лента с данными сервера',
        (tester) async {
      final app = TestApp();
      await pumpApp(tester, app, signedIn: false);

      await fillLogin(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
      await tester.pumpAndSettle();

      expect(find.textContaining("Levi's"), findsOneWidget);
      expect(await app.tokens.read(), 'tok-login');
      expect(app.session.isSignedIn, isTrue);
    });

    testWidgets('неверный пароль: SnackBar с русским сообщением, токена нет',
        (tester) async {
      final app = TestApp();
      await pumpApp(tester, app, signedIn: false);

      await fillLogin(tester, password: 'wrong-password');
      await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
      await tester.pumpAndSettle();

      expect(find.text('Неверный email или пароль'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(await app.tokens.read(), isNull);
    });

    testWidgets('регистрация: появляется поле «Имя», имя уходит на сервер',
        (tester) async {
      final app = TestApp();
      await pumpApp(tester, app, signedIn: false);

      await tester.tap(find.text('Нет аккаунта? Зарегистрируйтесь'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Имя'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Имя'), 'Ана');
      await fillLogin(tester, email: 'ana@test.md');
      await tester.tap(find.widgetWithText(FilledButton, 'Зарегистрироваться'));
      await tester.pumpAndSettle();

      expect(app.lastAuthBody!['name'], 'Ана');
      expect(find.textContaining("Levi's"), findsOneWidget);
    });

    testWidgets('регистрация с занятым e-mail: русское сообщение', (tester) async {
      final app = TestApp();
      await pumpApp(tester, app, signedIn: false);

      await tester.tap(find.text('Нет аккаунта? Зарегистрируйтесь'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Имя'), 'Ана');
      await fillLogin(tester, email: 'taken@test.md');
      await tester.tap(find.widgetWithText(FilledButton, 'Зарегистрироваться'));
      await tester.pumpAndSettle();

      expect(find.text('Аккаунт с этим email уже существует'), findsOneWidget);
    });

    testWidgets('выход: токен стёрт, экран входа, пользователь забыт',
        (tester) async {
      final app = TestApp();
      await pumpApp(tester, app, signedIn: false);
      await fillLogin(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Профиль'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Выйти'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Да, выйти'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(await app.tokens.read(), isNull);
      expect(app.session.isSignedIn, isFalse);
    });
  });

  group('данные с сервера', () {
    testWidgets('лента показывает вещи из хранилища', (tester) async {
      await pumpApp(tester, TestApp());

      expect(find.text('Лента'), findsWidgets);
      expect(find.textContaining("Levi's"), findsOneWidget);
    });

    testWidgets('остановленный сервер -> экран ошибки, «Повторить» -> данные',
        (tester) async {
      final app = TestApp();
      app.items.fail = true;
      await pumpApp(tester, app);

      expect(find.text(offlineMessage), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Повторить'), findsOneWidget);

      app.items.fail = false;
      await tester.tap(find.widgetWithText(FilledButton, 'Повторить'));
      await tester.pumpAndSettle();

      expect(find.text(offlineMessage), findsNothing);
      expect(find.textContaining("Levi's"), findsOneWidget);
    });

    testWidgets('пагинация: прокрутка вниз подгружает вторую страницу',
        (tester) async {
      final app = TestApp(
        items: FakeItemRepository(items: [
          for (var n = 1; n <= 45; n++)
            fakeItems[0].copyWith(id: 'x$n').withTitle('Вещь номер $n'),
        ]),
      );
      await pumpApp(tester, app);
      expect(find.text('Вещь номер 25'), findsNothing); // страница 2 ещё не нужна

      await tester.scrollUntilVisible(
        find.text('Вещь номер 25'),
        600,
        scrollable: find
            .descendant(of: find.byType(GridView), matching: find.byType(Scrollable))
            .first,
      );

      expect(find.text('Вещь номер 25'), findsOneWidget);
      expect(app.items.requestedPages, containsAllInOrder([1, 2]));
    });

    testWidgets('поиск идёт на сервер; крестик сбрасывает фильтр',
        (tester) async {
      await pumpApp(tester, TestApp());
      expect(find.textContaining('Nike'), findsOneWidget);

      await tester.enterText(find.byType(SearchBar), 'Levi');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.textContaining("Levi's"), findsOneWidget);
      expect(find.textContaining('Nike'), findsNothing);

      await tester.tap(find.byTooltip('Сбросить поиск'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nike'), findsOneWidget);
    });

    testWidgets('поиск без результатов: «Ничего не найдено»', (tester) async {
      await pumpApp(tester, TestApp());

      await tester.enterText(find.byType(SearchBar), 'абракадабра');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Ничего не найдено'), findsOneWidget);
    });
  });

  group('действия', () {
    testWidgets('избранное из карточки двигает badge в ленте', (tester) async {
      await pumpApp(tester, TestApp());
      expect(find.text('1'), findsNothing);

      await tester.tap(find.textContaining("Levi's"));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('бронь из карточки видна в «Мои покупки»', (tester) async {
      await pumpApp(tester, TestApp());

      await tester.tap(find.textContaining("Levi's"));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Забронировать'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Отменить бронь'), findsOneWidget);
      expect(find.text('Забронирована'), findsWidgets);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Покупки'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(MyPurchasesScreen),
          matching: find.textContaining("Levi's"),
        ),
        findsOneWidget,
      );
    });

    testWidgets('форма публикации: валидный submit -> вещь в «Мои объявления»',
        (tester) async {
      await pumpApp(tester, TestApp());

      await tester.tap(find.text('Мои вещи'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Добавить'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Название'), 'Тестовая парка');
      await tester.enterText(find.widgetWithText(TextFormField, 'Описание'),
          'Тёплая парка, носили один сезон');
      await tester.tap(find.text('Категория'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Верхняя одежда').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Размер'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('M').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Состояние'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Хорошее').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Цена'), '750');
      await tester.tap(find.widgetWithText(FilledButton, 'Опубликовать'));
      await tester.pumpAndSettle();

      expect(find.text('Мои объявления'), findsOneWidget);
      expect(find.text('Тестовая парка'), findsOneWidget);
    });

    testWidgets('невалидная форма ничего не отправляет', (tester) async {
      final app = TestApp();
      await pumpApp(tester, app);

      await tester.tap(find.text('Мои вещи'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Добавить'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Опубликовать'));
      await tester.pumpAndSettle();

      expect(find.text('Название обязательно'), findsOneWidget);
      expect(find.text('Новое объявление'), findsOneWidget);
    });

    testWidgets('сервер недоступен при публикации: SnackBar, данные в полях',
        (tester) async {
      final app = TestApp();
      await pumpApp(tester, app);
      await tester.tap(find.text('Мои вещи'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Добавить'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Название'), 'Тестовая парка');
      await tester.enterText(find.widgetWithText(TextFormField, 'Описание'),
          'Тёплая парка, носили один сезон');
      await tester.tap(find.text('Категория'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Верхняя одежда').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Размер'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('M').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Состояние'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Хорошее').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Цена'), '750');

      app.items.fail = true;
      await tester.tap(find.widgetWithText(FilledButton, 'Опубликовать'));
      await tester.pumpAndSettle();

      expect(find.text(offlineMessage), findsOneWidget);
      expect(find.text('Новое объявление'), findsOneWidget);
      expect(find.text('Тестовая парка'), findsOneWidget); // ввод остался
    });

    testWidgets('удаление с подтверждением: вещь исчезает из списка',
        (tester) async {
      await pumpApp(tester, TestApp());
      const title = 'Джинсовая куртка Pull&Bear, светлая варёнка';

      await tester.tap(find.text('Мои вещи'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить объявление'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
      await tester.pumpAndSettle();

      expect(find.text('Мои объявления'), findsOneWidget);
      expect(find.text(title), findsNothing);
    });
  });

  group('поток 401', () {
    testWidgets('мёртвый токен: стёрт из prefs, приложение само на login',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({'auth_token': 'dead-token'});

      final tokens = TokenStore();
      final session = SessionModel()..signIn(fakeCurrentUser);
      router = buildRouter('/feed');
      final api = ApiClient(
        'http://test',
        tokens,
        // сервер на каждый запрос отвечает 401, как при другом JWT_SECRET
        client: MockClient((_) async => jsonReply({
              'error': {'code': 'UNAUTHORIZED', 'message': 'x'},
            }, 401)),
        onUnauthorized: () {
          router.go('/login');
          session.signOut();
        },
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: appProviders(
            config: const ApiConfig('http://test'),
            auth: TestApp().auth,
            files: FileApi(api, 'http://test'),
            session: session,
            items: HttpItemRepository(api),
            reservations: HttpReservationRepository(api),
          ),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(await tokens.read(), isNull);
      expect(session.isSignedIn, isFalse);
    });
  });
}

extension on Item {
  Item withTitle(String title) => Item(
        id: id,
        title: title,
        description: description,
        price: price,
        size: size,
        condition: condition,
        category: category,
        owner: owner,
        status: status,
        createdAt: createdAt,
      );
}
