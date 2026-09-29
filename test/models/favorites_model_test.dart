import 'package:flutter_test/flutter_test.dart';

import 'package:second_hand_market/models/favorites_model.dart';

void main() {
  test('toggle добавляет и убирает вещь, счётчик меняется', () {
    final model = FavoritesModel();

    model.toggle('i1');
    expect(model.isFavorite('i1'), isTrue);
    expect(model.count, 1);

    model.toggle('i1');
    expect(model.isFavorite('i1'), isFalse);
    expect(model.count, 0);
  });

  test('каждая мутация извещает подписчиков', () {
    final model = FavoritesModel();
    var notified = 0;
    model.addListener(() => notified++);

    model.toggle('i1');
    model.toggle('i2');
    model.toggle('i1');

    expect(notified, 3);
  });

  test('коллекция наружу read-only: в обход модели её не изменить', () {
    final model = FavoritesModel()..toggle('i1');

    expect(() => model.ids.add('i2'), throwsUnsupportedError);
    expect(model.count, 1);
  });
}
