import 'package:flutter_test/flutter_test.dart';

import 'package:second_hand_market/data/catalog.dart';
import 'package:second_hand_market/data/item.dart';
import 'package:second_hand_market/data/mock_data.dart';
import 'package:second_hand_market/data/mock_item_repository.dart';
import 'package:second_hand_market/data/mock_network.dart';
import 'package:second_hand_market/models/items_model.dart';

Item draft() => Item(
      id: '',
      title: 'Тестовая куртка',
      description: 'Описание тестовой куртки',
      price: 500,
      size: 'M',
      condition: 'Отличное',
      category: catalogCategories.first,
      owner: mockCurrentUser,
      status: ItemStatus.available,
      createdAt: DateTime(2026, 9, 29),
    );

void main() {
  late MockNetwork network;
  late ItemsModel model;

  setUp(() {
    network = MockNetwork(latency: Duration.zero);
    model = ItemsModel(MockItemRepository(network));
  });

  test('load проходит «грузится» → «данные» и извещает дважды', () async {
    final states = <bool>[];
    model.addListener(() => states.add(model.isLoading));

    await model.load();

    expect(states, [true, false]);
    expect(model.error, isNull);
    expect(model.items, isNotEmpty);
  });

  test('при аварии load даёт ошибку, а не исключение', () async {
    network.simulateError = true;

    await model.load();

    expect(model.error, MockNetwork.errMessage);
    expect(model.isLoading, isFalse);
  });

  test('retry после аварии возвращает данные', () async {
    network.simulateError = true;
    await model.load();
    network.simulateError = false;

    await model.load();

    expect(model.error, isNull);
    expect(model.items, isNotEmpty);
  });

  test('лента и «мои вещи» делят список по владельцу', () async {
    await model.load();

    final feed = model.feedFor(mockCurrentUser);
    final mine = model.ownedBy(mockCurrentUser);

    expect(feed.every((i) => i.owner.id != mockCurrentUser.id), isTrue);
    expect(mine.every((i) => i.owner.id == mockCurrentUser.id), isTrue);
    expect(feed.length + mine.length, model.items.length);
  });

  test('add: id выдаёт хранилище, вещь появляется первой, подписчики знают',
      () async {
    await model.load();
    final before = model.items.length;
    var notified = 0;
    model.addListener(() => notified++);

    final error = await model.add(draft());

    expect(error, isNull);
    expect(model.items.length, before + 1);
    expect(model.items.first.title, 'Тестовая куртка');
    expect(model.items.first.id, isNot(''));
    expect(notified, 1);
  });

  test('add при аварии возвращает сообщение и не трогает состояние', () async {
    await model.load();
    final before = model.items.length;
    network.simulateError = true;

    final error = await model.add(draft());

    expect(error, MockNetwork.errMessage);
    expect(model.items.length, before);
  });

  test('remove убирает вещь; повторное удаление — ошибка, а не crash',
      () async {
    await model.load();
    final id = model.items.first.id;

    expect(await model.remove(id), isNull);
    expect(model.byId(id), isNull);
    expect(await model.remove(id), isNotNull);
  });

  test('update меняет статус вещи на месте', () async {
    await model.load();
    final item = model.items.firstWhere((i) => i.status == ItemStatus.available);

    final error = await model.update(item.copyWith(status: ItemStatus.reserved));

    expect(error, isNull);
    expect(model.byId(item.id)!.status, ItemStatus.reserved);
  });

  test('items наружу read-only: model.items.add(...) невозможен', () async {
    await model.load();

    expect(() => model.items.add(draft()), throwsUnsupportedError);
  });
}
