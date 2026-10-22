import 'package:flutter_test/flutter_test.dart';

import 'package:second_hand_market/data/catalog.dart';
import 'package:second_hand_market/data/item.dart';
import 'package:second_hand_market/models/items_model.dart';

import '../support/fake_data.dart';
import '../support/fake_repositories.dart';

Item otherItem(int n) => Item(
      id: 'x$n',
      title: 'Вещь номер $n',
      description: 'Описание вещи для проверки списка',
      price: 100,
      size: 'M',
      condition: 'Хорошее',
      category: catalogCategories.first,
      owner: fakeUsers[1],
      status: ItemStatus.available,
      createdAt: DateTime(2026, 9, 1),
    );

Item myDraft() => Item(
      id: '',
      title: 'Тестовая куртка',
      description: 'Описание тестовой куртки',
      price: 500,
      size: 'M',
      condition: 'Отличное',
      category: catalogCategories.first,
      owner: fakeCurrentUser,
      status: ItemStatus.available,
      createdAt: DateTime(2026, 9, 29),
    );

void main() {
  late FakeItemRepository repo;
  late ItemsModel model;

  ItemsModel modelWith(int others, {int pageSize = 20}) {
    repo = FakeItemRepository(
      items: [for (var n = 1; n <= others; n++) otherItem(n), ...fakeItems.skip(10)],
    );
    return ItemsModel(repo, userId: 'u1', pageSize: pageSize);
  }

  setUp(() {
    repo = FakeItemRepository();
    model = ItemsModel(repo, userId: 'u1');
  });

  group('лента: триада состояний', () {
    test('load проходит «грузится» -> «данные» и извещает дважды', () async {
      final states = <bool>[];
      model.addListener(() => states.add(model.isLoading));

      await model.load();

      expect(states, [true, false]);
      expect(model.error, isNull);
      expect(model.feed, isNotEmpty);
    });

    test('в ленте только чужие вещи', () async {
      await model.load();

      expect(model.feed.every((i) => i.owner.id != 'u1'), isTrue);
    });

    test('сбой сети: Err в error, а не исключение; после починки retry работает',
        () async {
      repo.fail = true;
      await model.load();

      expect(model.error, offlineMessage);
      expect(model.isLoading, isFalse);

      repo.fail = false;
      await model.load();

      expect(model.error, isNull);
      expect(model.feed, isNotEmpty);
    });

    test('feed наружу read-only: model.feed.add(...) невозможен', () async {
      await model.load();

      expect(() => model.feed.add(otherItem(1)), throwsUnsupportedError);
    });
  });

  group('пагинация', () {
    test('полная страница -> hasMore, loadMore приклеивает следующую', () async {
      model = modelWith(45);

      await model.load();
      expect(model.feed.length, 20);
      expect(model.hasMore, isTrue);

      await model.loadMore();
      expect(model.feed.length, 40);
      expect(model.hasMore, isTrue);

      await model.loadMore();
      expect(model.feed.length, 45);
      expect(model.hasMore, isFalse);
    });

    test('неполная страница: больше не просим', () async {
      model = modelWith(5);

      await model.load();
      await model.loadMore();

      expect(model.hasMore, isFalse);
      expect(repo.requestedPages, [1]);
    });

    test('guard: одну страницу дважды не просят (дублей нет)', () async {
      model = modelWith(45);
      await model.load();

      final a = model.loadMore();
      final b = model.loadMore(); // второй вызов в разгар первого
      await Future.wait([a, b]);

      expect(repo.requestedPages, [1, 2]);
      expect(model.feed.map((i) => i.id).toSet().length, model.feed.length);
    });

    test('loadMore не извещает синхронно: его зовут из build', () async {
      model = modelWith(45);
      await model.load();
      var notified = 0;
      model.addListener(() => notified++);

      final future = model.loadMore();
      expect(notified, 0); // до ответа сервера извещения нет
      await future;

      expect(notified, 1);
    });

    test('ошибка на хвосте: список цел, retryLoadMore дозагружает', () async {
      model = modelWith(45);
      await model.load();
      repo.fail = true;

      await model.loadMore();

      expect(model.loadMoreError, offlineMessage);
      expect(model.feed.length, 20);

      repo.fail = false;
      await model.retryLoadMore();

      expect(model.loadMoreError, isNull);
      expect(model.feed.length, 40);
    });
  });

  group('поиск', () {
    test('load(search:) фильтрует, а «Повторить» сохраняет фильтр', () async {
      await model.load(search: 'Levi');
      expect(model.feed.length, 1);
      expect(model.search, 'Levi');

      await model.load(); // retry без аргумента

      expect(model.search, 'Levi');
      expect(model.feed.length, 1);
    });

    test('пустая строка сбрасывает фильтр', () async {
      await model.load(search: 'Levi');
      await model.load(search: '');

      expect(model.feed.length, greaterThan(1));
    });
  });

  group('мои объявления и кэш', () {
    test('loadMine приносит только мои вещи', () async {
      await model.loadMine();

      expect(model.mine, isNotEmpty);
      expect(model.mine.every((i) => i.owner.id == 'u1'), isTrue);
    });

    test('byId находит вещь из ленты и из «моих»', () async {
      await model.load();
      await model.loadMine();

      expect(model.byId('i1'), isNotNull);
      expect(model.byId('i11'), isNotNull);
      expect(model.byId('нет-такой'), isNull);
    });

    test('add: id выдаёт сервер, вещь первой в «моих», в ленту не попадает',
        () async {
      await model.load();
      await model.loadMine();
      final inFeed = model.feed.length;
      var notified = 0;
      model.addListener(() => notified++);

      final error = await model.add(myDraft());

      expect(error, isNull);
      expect(model.mine.first.title, 'Тестовая куртка');
      expect(model.mine.first.id, isNot(''));
      expect(model.feed.length, inFeed);
      expect(notified, 1);
    });

    test('add при сбое возвращает сообщение и не трогает состояние', () async {
      await model.loadMine();
      final before = model.mine.length;
      repo.fail = true;

      final error = await model.add(myDraft());

      expect(error, offlineMessage);
      expect(model.mine.length, before);
    });

    test('remove убирает вещь отовсюду; повтор даёт ошибку, а не crash',
        () async {
      await model.load();
      await model.loadMine();

      expect(await model.remove('i11'), isNull);
      expect(model.byId('i11'), isNull);
      expect(model.mine.any((i) => i.id == 'i11'), isFalse);
      expect(await model.remove('i11'), isNotNull);
    });

    test('apply подменяет вещь в кэше и извещает, чужих id не знает', () async {
      await model.load();
      var notified = 0;
      model.addListener(() => notified++);

      model.apply(model.byId('i1')!.copyWith(status: ItemStatus.reserved));
      expect(model.byId('i1')!.status, ItemStatus.reserved);
      expect(model.feed.firstWhere((i) => i.id == 'i1').status,
          ItemStatus.reserved);
      expect(notified, 1);

      model.apply(otherItem(999)); // такой вещи никто не загружал
      expect(model.byId('x999'), isNull);
      expect(notified, 1);
    });

    test('update меняет вещь через repository', () async {
      await model.load();

      final error = await model
          .update(model.byId('i1')!.copyWith(status: ItemStatus.sold));

      expect(error, isNull);
      expect(model.byId('i1')!.status, ItemStatus.sold);
    });
  });
}
