import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:second_hand_market/data/api_client.dart';
import 'package:second_hand_market/data/http_item_repository.dart';
import 'package:second_hand_market/data/item.dart';
import 'package:second_hand_market/data/result.dart';
import 'package:second_hand_market/data/token_store.dart';

Map<String, dynamic> itemJson(int id, {String status = 'available'}) => {
      'id': id,
      'title': 'Вещь $id',
      'description': 'Описание вещи',
      'price': 100,
      'size': 'M',
      'condition': 'Хорошее',
      'categoryId': 'c1',
      'status': status,
      'imageUrl': '',
      'createdAt': '2026-09-16T10:00:00.000Z',
      'owner': {'id': 2, 'name': 'Ион', 'email': 'ion@mail.md'},
    };

// как у настоящего сервера: JSON с charset=utf-8, иначе кириллица не кодируется
http.Response reply(String body, int status) => http.Response(body, status,
    headers: {'content-type': 'application/json; charset=utf-8'});

String page(List<Map<String, dynamic>> items) => jsonEncode(
    {'items': items, 'page': 1, 'limit': 20, 'total': items.length});

HttpItemRepository repoFor(Future<http.Response> Function(http.Request) h) =>
    HttpItemRepository(
        ApiClient('http://x', TokenStore(), client: MockClient(h)));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'auth_token': 'T'}));

  test('fetchAll: GET /items, список достаётся из конверта', () async {
    late http.Request seen;
    final repo = repoFor((r) async {
      seen = r;
      return reply(page([itemJson(1), itemJson(2)]), 200);
    });

    final result = await repo.fetchAll();

    expect(seen.method, 'GET');
    expect(seen.url.path, '/items');
    expect(seen.url.queryParameters, {'page': '1', 'limit': '20'});
    expect((result as Ok<List<Item>>).value.map((i) => i.id), ['1', '2']);
  });

  test('fetchAll с page, limit, search и mine: всё уходит в query', () async {
    late http.Request seen;
    final repo = repoFor((r) async {
      seen = r;
      return reply(page([]), 200);
    });

    await repo.fetchAll(page: 3, limit: 5, search: 'Зара', mine: true);

    expect(seen.url.queryParameters,
        {'page': '3', 'limit': '5', 'search': 'Зара', 'mine': 'true'});
  });

  test('старый вызов fetchAll() компилируется без изменений (L4 не сломан)', () async {
    final repo = repoFor((_) async => reply(page([]), 200));

    final Result<List<Item>> result = await repo.fetchAll();

    expect(result, isA<Ok<List<Item>>>());
  });

  test('fetchById: 404 -> Err с русским сообщением', () async {
    final repo = repoFor((_) async => reply(
        '{"error":{"code":"NOT_FOUND","message":"Item not found"}}', 404));

    final result = await repo.fetchById('999');

    expect((result as Err).msg, 'Запись не существует');
  });

  test('create: POST /items с телом без id, id приходит от сервера', () async {
    late http.Request seen;
    final repo = repoFor((r) async {
      seen = r;
      return reply(jsonEncode(itemJson(77)), 201);
    });
    final draft = Item.fromJson(itemJson(1));

    final result = await repo.create(draft);

    expect(seen.method, 'POST');
    expect(jsonDecode(seen.body).containsKey('id'), isFalse);
    expect((result as Ok<Item>).value.id, '77');
  });

  test('update: PUT /items/{id}, статус едет в теле', () async {
    late http.Request seen;
    final repo = repoFor((r) async {
      seen = r;
      return reply(jsonEncode(itemJson(5, status: 'sold')), 200);
    });
    final item = Item.fromJson(itemJson(5)).copyWith(status: ItemStatus.sold);

    await repo.update(item);

    expect(seen.method, 'PUT');
    expect(seen.url.path, '/items/5');
    expect(jsonDecode(seen.body)['status'], 'sold');
  });

  test('delete: 204 с пустым телом -> Ok без разбора JSON', () async {
    final repo = repoFor((_) async => reply('', 204));

    final result = await repo.delete('5');

    expect(result, isA<Ok<void>>());
  });

  test('delete: на чужую вещь 404 -> Err', () async {
    final repo = repoFor((_) async => reply(
        '{"error":{"code":"NOT_FOUND","message":"x"}}', 404));

    expect(await repo.delete('5'), isA<Err<void>>());
  });

  test('отказ дороги, статуса и тела ложится в Err(msg) для UI L4', () async {
    final down = repoFor((_) async => throw const SocketException('x'));
    final html = repoFor((_) async => reply('<html/>', 200));
    final broken = repoFor((_) async => reply('{"items":[{"id":1}]}', 200));

    expect((await down.fetchAll() as Err).msg, 'Нет сети - повторите попытку');
    expect((await html.fetchAll() as Err).msg, 'Ответ не тот, что обещан');
    expect((await broken.fetchAll() as Err).msg, 'Ответ не тот, что обещан');
  });
}
