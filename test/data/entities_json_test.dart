import 'package:flutter_test/flutter_test.dart';

import 'package:second_hand_market/data/item.dart';
import 'package:second_hand_market/data/user.dart';

Map<String, dynamic> itemJson({Object price = 350}) => {
      'id': 7,
      'title': "Джинсы Levi's",
      'description': 'Плотный деним',
      'price': price,
      'size': 'W32 L32',
      'condition': 'Отличное',
      'categoryId': 'c2',
      'status': 'reserved',
      'imageUrl': '/files/3',
      'createdAt': '2026-09-16T10:00:00.000Z',
      'owner': {'id': 2, 'name': 'Ион Русу', 'email': 'ion@mail.md'},
    };

void main() {
  test('Item.fromJson: id становится строкой, продавец едет вместе с вещью', () {
    final item = Item.fromJson(itemJson());

    expect(item.id, '7');
    expect(item.owner.id, '2');
    expect(item.owner.name, 'Ион Русу');
    expect(item.category.name, 'Джинсы и брюки');
    expect(item.status, ItemStatus.reserved);
    expect(item.imageUrl, '/files/3');
    expect(item.createdAt.year, 2026);
  });

  test('цена 120 приходит как int и не роняет разбор', () {
    expect(Item.fromJson(itemJson(price: 120)).price, 120.0);
    expect(Item.fromJson(itemJson(price: 99.5)).price, 99.5);
  });

  test('неизвестная категория не роняет разбор', () {
    final json = itemJson()..['categoryId'] = 'c999';

    expect(Item.fromJson(json).category.id, 'c1');
  });

  test('сломанный JSON даёт TypeError или FormatException, а не тихий мусор', () {
    expect(() => Item.fromJson({'id': 1}), throwsA(isA<TypeError>()));
    final bad = itemJson()..['createdAt'] = 'вчера';
    expect(() => Item.fromJson(bad), throwsFormatException);
  });

  test('toJson не содержит id и статуса: их даёт сервер', () {
    final json = Item.fromJson(itemJson()).toJson();

    expect(json.containsKey('id'), isFalse);
    expect(json.containsKey('status'), isFalse);
    expect(json['categoryId'], 'c2');
    expect(json['title'], "Джинсы Levi's");
  });

  test('User.fromJson', () {
    final user = User.fromJson({'id': 5, 'name': 'Ana', 'email': 'a@b.md'});

    expect(user.id, '5');
    expect(user.name, 'Ana');
  });
}
