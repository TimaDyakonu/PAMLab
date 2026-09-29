import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:second_hand_market/data/mock_network.dart';
import 'package:second_hand_market/router.dart';
import 'package:second_hand_market/screens/my_purchases_screen.dart';

import 'support/test_app.dart';

Future<void> pumpApp(WidgetTester tester, MockNetwork network) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  router.go('/login');
  await tester.pumpWidget(buildTestApp(network: network));
  await tester.pumpAndSettle();

  await tester.enterText(
      find.widgetWithText(TextFormField, 'E-mail'), 'admin@secondhand.md');
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Пароль'), 'secret123');
  await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
  await tester.pumpAndSettle();
}

void main() {
  late MockNetwork network;

  setUp(() => network = MockNetwork(latency: Duration.zero));

  testWidgets('после входа лента показывает вещи из хранилища', (tester) async {
    await pumpApp(tester, network);

    expect(find.text('Лента'), findsWidgets);
    expect(find.textContaining("Levi's"), findsOneWidget);
  });

  testWidgets('авария → экран ошибки, «Повторить» после починки → данные',
      (tester) async {
    await pumpApp(tester, network);

    network.simulateError = true;
    await tester.tap(find.byTooltip('Обновить'));
    await tester.pumpAndSettle();

    expect(find.text(MockNetwork.errMessage), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Повторить'), findsOneWidget);

    network.simulateError = false;
    await tester.tap(find.widgetWithText(FilledButton, 'Повторить'));
    await tester.pumpAndSettle();

    expect(find.text(MockNetwork.errMessage), findsNothing);
    expect(find.textContaining("Levi's"), findsOneWidget);
  });

  testWidgets('избранное из карточки двигает badge в ленте', (tester) async {
    await pumpApp(tester, network);
    expect(find.byType(Badge), findsOneWidget);
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
    await pumpApp(tester, network);

    await tester.tap(find.textContaining("Levi's"));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Забронировать'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Отменить бронь'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Покупки'));
    await tester.pumpAndSettle();

    // лента остаётся жить под вкладкой (IndexedStack), поэтому ищем внутри экрана
    expect(
      find.descendant(
        of: find.byType(MyPurchasesScreen),
        matching: find.textContaining("Levi's"),
      ),
      findsOneWidget,
    );
  });

  testWidgets('форма публикации: валидный submit → вещь в «Мои объявления»',
      (tester) async {
    await pumpApp(tester, network);

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

  testWidgets('невалидная форма ничего не пишет в модель', (tester) async {
    await pumpApp(tester, network);

    await tester.tap(find.text('Мои вещи'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Опубликовать'));
    await tester.pumpAndSettle();

    expect(find.text('Название обязательно'), findsOneWidget);
    expect(find.text('Новое объявление'), findsOneWidget);
  });

  testWidgets('удаление с подтверждением: вещь исчезает из списка',
      (tester) async {
    await pumpApp(tester, network);
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
}
