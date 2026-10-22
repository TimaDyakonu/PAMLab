import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:second_hand_market/data/api_client.dart';
import 'package:second_hand_market/data/api_config.dart';
import 'package:second_hand_market/data/auth_api.dart';
import 'package:second_hand_market/data/file_api.dart';
import 'package:second_hand_market/data/token_store.dart';
import 'package:second_hand_market/main.dart';
import 'package:second_hand_market/models/session_model.dart';
import 'package:second_hand_market/router.dart';

import 'fake_data.dart';
import 'fake_repositories.dart';

/// Ответ сервера с charset, как у настоящего (иначе кириллица не кодируется).
http.Response jsonReply(Object body, int status) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// Приложение целиком: то же дерево провайдеров, что в main(), но данные
/// берутся из fake-репозиториев, а сервер входа изображает MockClient.
class TestApp {
  TestApp({FakeItemRepository? items, FakeReservationRepository? reservations})
      : items = items ?? FakeItemRepository(),
        tokens = TokenStore() {
    this.reservations = reservations ?? FakeReservationRepository(this.items);
    auth = AuthApi(
      ApiClient('http://test', tokens, client: MockClient(_loginServer)),
      tokens,
    );
  }

  final FakeItemRepository items;
  late final FakeReservationRepository reservations;
  final TokenStore tokens;
  final session = SessionModel();
  late final AuthApi auth;

  /// Что пришло на сервер входа: тело последнего register/login.
  Map<String, dynamic>? lastAuthBody;

  Future<http.Response> _loginServer(http.Request request) async {
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    lastAuthBody = body;
    final user = {
      'id': fakeCurrentUser.id,
      'email': body['email'],
      'name': body['name'] ?? fakeCurrentUser.name,
    };
    if (request.url.path == '/auth/register') {
      if (body['email'] == 'taken@test.md') {
        return jsonReply({
          'error': {'code': 'EMAIL_TAKEN', 'message': 'x'},
        }, 409);
      }
      return jsonReply({'token': 'tok-new', 'user': user}, 201);
    }
    if (body['password'] == 'wrong-password') {
      return jsonReply({
        'error': {'code': 'UNAUTHORIZED', 'message': 'x'},
      }, 401);
    }
    return jsonReply({'token': 'tok-login', 'user': user}, 200);
  }

  /// Дерево приложения, начиная с экрана входа (или ленты, если вход уже есть).
  Widget build({bool signedIn = false}) {
    SharedPreferences.setMockInitialValues({});
    if (signedIn) session.signIn(fakeCurrentUser);
    router = buildRouter(signedIn ? '/feed' : '/login');
    final api = ApiClient('http://test', tokens);
    return MultiProvider(
      providers: appProviders(
        config: const ApiConfig('http://test'),
        auth: auth,
        files: FileApi(api, 'http://test'),
        session: session,
        items: items,
        reservations: reservations,
      ),
      child: const MyApp(),
    );
  }
}
