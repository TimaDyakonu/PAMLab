import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:second_hand_market/data/api_client.dart';
import 'package:second_hand_market/data/result.dart';
import 'package:second_hand_market/data/token_store.dart';

const _json = {'content-type': 'application/json'};

ApiClient clientFor(
  Future<http.Response> Function(http.Request) handler, {
  void Function()? onUnauthorized,
  Duration timeout = const Duration(seconds: 2),
}) =>
    ApiClient(
      'http://x',
      TokenStore(),
      client: MockClient(handler),
      onUnauthorized: onUnauthorized,
      timeout: timeout,
    );

Future<Result<Object?>> get(ApiClient api, {bool authorized = true}) =>
    api.send<Object?>('GET', '/p',
        ok: {200}, parse: (json) => json, authorized: authorized);

String msgOf(Result<Object?> r) => (r as Err).msg;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'auth_token': 'T0K'}));

  group('слой 1: упавшая дорога бросает, ловим по типам', () {
    test('SocketException -> нет сети', () async {
      final api = clientFor((_) async => throw const SocketException('down'));

      expect(msgOf(await get(api)), 'Нет сети - повторите попытку');
    });

    test('ClientException -> нет сети', () async {
      final api = clientFor((_) async => throw http.ClientException('reset'));

      expect(msgOf(await get(api)), 'Нет сети - повторите попытку');
    });

    test('зависший сервер -> TimeoutException -> сервер не отвечает', () async {
      final api = clientFor(
        (_) => Future.delayed(const Duration(seconds: 1), () => http.Response('{}', 200)),
        timeout: const Duration(milliseconds: 30),
      );

      expect(msgOf(await get(api)), 'Сервер не отвечает');
    });
  });

  group('слой 2: дурная весть читается из statusCode и конверта', () {
    test('404 с конвертом -> русское сообщение', () async {
      final api = clientFor((_) async => http.Response(
          '{"error":{"code":"NOT_FOUND","message":"Item not found"}}', 404,
          headers: _json));

      expect(msgOf(await get(api)), 'Запись не существует');
    });

    test('500 с HTML -> Ошибка сервера (500)', () async {
      final api = clientFor((_) async => http.Response('<html>oops</html>', 500));

      expect(msgOf(await get(api)), 'Ошибка сервера (500)');
    });
  });

  group('слой 3: тело-сюрприз падает при разборе', () {
    test('HTML вместо JSON на 200 -> FormatException -> Ответ не тот', () async {
      final api = clientFor((_) async => http.Response('<html>proxy</html>', 200));

      expect(msgOf(await get(api)), 'Ответ не тот, что обещан');
    });

    test('JSON не того вида -> TypeError -> Ответ не тот', () async {
      final api = clientFor((_) async => http.Response('[1,2]', 200));
      final result = await api.send<String>('GET', '/p',
          ok: {200}, parse: (json) => (json as Map<String, dynamic>)['x'] as String);

      expect((result as Err).msg, 'Ответ не тот, что обещан');
    });
  });

  group('успех', () {
    test('200 -> Ok с разобранным JSON', () async {
      final api = clientFor((_) async => http.Response('{"a":1}', 200));

      final result = await get(api);

      expect((result as Ok).value, {'a': 1});
    });

    test('204 с пустым телом: jsonDecode на нём не вызывается', () async {
      final api = clientFor((_) async => http.Response('', 204));

      final result = await api.send<String>('DELETE', '/p',
          ok: {204}, parse: (json) => json == null ? 'пусто' : 'есть');

      expect((result as Ok).value, 'пусто');
    });

    test('токен уходит в заголовке Authorization: Bearer', () async {
      late http.Request seen;
      final api = clientFor((r) async {
        seen = r;
        return http.Response('{}', 200);
      });

      await get(api);

      expect(seen.headers['Authorization'], 'Bearer T0K');
    });

    test('query-параметры попадают в адрес, кириллица кодируется', () async {
      late http.Request seen;
      final api = clientFor((r) async {
        seen = r;
        return http.Response('{}', 200);
      });

      await api.send<Object?>('GET', '/items',
          ok: {200}, parse: (j) => j, query: {'page': '2', 'search': 'Зара'});

      expect(seen.url.queryParameters['page'], '2');
      expect(seen.url.queryParameters['search'], 'Зара');
    });
  });

  group('401: пропуск умер', () {
    test('токен стирается, корень извещается, сообщение русское', () async {
      var notified = 0;
      final api = clientFor(
        (_) async => http.Response(
            '{"error":{"code":"UNAUTHORIZED","message":"x"}}', 401),
        onUnauthorized: () => notified++,
      );

      final result = await get(api);

      expect(msgOf(result), 'Сессия истекла - войдите снова');
      expect(await TokenStore().read(), isNull);
      expect(notified, 1);
    });

    test('на запросе без пропуска (login) 401 это неверный пароль, токен цел', () async {
      var notified = 0;
      final api = clientFor(
        (_) async => http.Response(
            '{"error":{"code":"UNAUTHORIZED","message":"x"}}', 401),
        onUnauthorized: () => notified++,
      );

      final result = await get(api, authorized: false);

      expect(msgOf(result), 'Неверный email или пароль');
      expect(await TokenStore().read(), 'T0K');
      expect(notified, 0);
    });
  });
}
