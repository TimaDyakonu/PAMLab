import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:second_hand_market/data/api_client.dart';
import 'package:second_hand_market/data/auth_api.dart';
import 'package:second_hand_market/data/result.dart';
import 'package:second_hand_market/data/token_store.dart';

const _okBody =
    '{"token":"tok123","user":{"id":4,"email":"ana@test.md","name":"Ana"}}';

AuthApi authFor(Future<http.Response> Function(http.Request) handler) {
  final tokens = TokenStore();
  return AuthApi(
    ApiClient('http://x', tokens, client: MockClient(handler)),
    tokens,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('login: токен сохраняется в prefs, пользователь возвращается', () async {
    final auth = authFor((_) async => http.Response(_okBody, 200));

    final result = await auth.login('ana@test.md', 'parola123');

    expect((result as Ok).value.name, 'Ana');
    expect(await TokenStore().read(), 'tok123');
  });

  test('register шлёт email, пароль и имя на /auth/register', () async {
    late http.Request seen;
    final auth = authFor((r) async {
      seen = r;
      return http.Response(_okBody, 201);
    });

    await auth.register('ana@test.md', 'parola123', 'Ana');

    expect(seen.url.path, '/auth/register');
    expect(jsonDecode(seen.body),
        {'email': 'ana@test.md', 'password': 'parola123', 'name': 'Ana'});
  });

  test('ПАРОЛЬ нигде не сохраняется: в prefs только токен', () async {
    final auth = authFor((_) async => http.Response(_okBody, 200));

    await auth.login('ana@test.md', 'parola123');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), {'auth_token'});
    expect(prefs.getString('auth_token'), isNot(contains('parola123')));
  });

  test('неверный пароль: 401 -> русское сообщение, токена нет', () async {
    final auth = authFor((_) async => http.Response(
        '{"error":{"code":"UNAUTHORIZED","message":"Invalid email or password"}}', 401));

    final result = await auth.login('ana@test.md', 'bad');

    expect((result as Err).msg, 'Неверный email или пароль');
    expect(await TokenStore().read(), isNull);
  });

  test('email занят: 409 EMAIL_TAKEN -> русское сообщение', () async {
    final auth = authFor((_) async => http.Response(
        '{"error":{"code":"EMAIL_TAKEN","message":"x"}}', 409));

    final result = await auth.register('ana@test.md', 'parola123', 'Ana');

    expect((result as Err).msg, 'Аккаунт с этим email уже существует');
  });

  test('logout стирает токен', () async {
    final auth = authFor((_) async => http.Response(_okBody, 200));
    await auth.login('ana@test.md', 'parola123');

    await auth.logout();

    expect(await TokenStore().read(), isNull);
  });

  test('me: GET /me с токеном возвращает пользователя', () async {
    SharedPreferences.setMockInitialValues({'auth_token': 'tok123'});
    late http.Request seen;
    final auth = authFor((r) async {
      seen = r;
      return http.Response('{"id":4,"email":"ana@test.md","name":"Ana"}', 200);
    });

    final result = await auth.me();

    expect(seen.headers['Authorization'], 'Bearer tok123');
    expect((result as Ok).value.id, '4');
  });
}
