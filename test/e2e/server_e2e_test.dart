// Сквозной тест по-настоящему: поднимает server/ на отдельном порту и ходит в
// него теми же классами, что и приложение (ApiClient, AuthApi, репозитории,
// FileApi). Мок-ответы показывают, что разбор верен для придуманного JSON, а
// этот тест: что он верен для JSON, который отдаёт настоящий сервер.
@Timeout(Duration(minutes: 3))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:second_hand_market/data/api_client.dart';
import 'package:second_hand_market/data/auth_api.dart';
import 'package:second_hand_market/data/file_api.dart';
import 'package:second_hand_market/data/http_item_repository.dart';
import 'package:second_hand_market/data/http_reservation_repository.dart';
import 'package:second_hand_market/data/item.dart';
import 'package:second_hand_market/data/reservation.dart';
import 'package:second_hand_market/data/result.dart';
import 'package:second_hand_market/data/token_store.dart';

const _port = 8791;
const _base = 'http://localhost:$_port';

late Process _server;

Future<void> _waitForServer() async {
  final client = HttpClient();
  for (var i = 0; i < 180; i++) {
    try {
      final request = await client.getUrl(Uri.parse('$_base/health'));
      final response = await request.close();
      await response.drain<void>();
      if (response.statusCode == 200) return;
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  throw StateError('Сервер не поднялся на порту $_port');
}

T ok<T>(Result<T> result) {
  if (result is Ok<T>) return result.value;
  fail('Ожидали Ok, получили ${(result as Err).msg}');
}

String err<T>(Result<T> result) {
  if (result is Err<T>) return result.msg;
  fail('Ожидали Err, получили Ok');
}

/// Токен в памяти: у двух пользователей одного теста общий SharedPreferences
/// перезаписал бы токен друг друга.
class MemoryTokenStore extends TokenStore {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> save(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

/// Свежий пользователь с собственным хранилищем токена.
Future<({ApiClient api, AuthApi auth, TokenStore tokens})> newUser(
  String name,
) async {
  final tokens = MemoryTokenStore();
  final api = ApiClient(_base, tokens);
  final auth = AuthApi(api, tokens);
  final email = '$name${DateTime.now().microsecondsSinceEpoch}@e2e.md';
  ok(await auth.register(email, 'parola123', name));
  return (api: api, auth: auth, tokens: tokens);
}

void main() {
  setUpAll(() async {
    _server = await Process.start(
      'dart',
      ['run', 'bin/server.dart'],
      workingDirectory: 'server',
      environment: {'PORT': '$_port'},
      runInShell: true,
    );
    unawaited(_server.stdout.drain<void>());
    unawaited(_server.stderr.drain<void>());
    await _waitForServer();
  });

  tearDownAll(() async {
    // runInShell: убиваем всё дерево процессов, иначе порт останется занятым
    if (Platform.isWindows) {
      await Process.run('taskkill', ['/F', '/T', '/PID', '${_server.pid}']);
    } else {
      _server.kill();
    }
  });

  test('регистрация и вход по настоящему контракту; токен лежит в prefs', () async {
    SharedPreferences.setMockInitialValues({});
    final tokens = TokenStore();
    final auth = AuthApi(ApiClient(_base, tokens), tokens);
    final email = 'login${DateTime.now().microsecondsSinceEpoch}@e2e.md';

    final registered = ok(await auth.register(email, 'parola123', 'Анна'));
    expect(registered.name, 'Анна');
    expect(await tokens.read(), isNotNull);

    await auth.logout();
    expect(await tokens.read(), isNull);

    final user = ok(await auth.login(email, 'parola123'));
    expect(user.email, email);
    expect(ok(await auth.me()).id, user.id);

    expect(err(await auth.register(email, 'parola123', 'Анна')),
        'Аккаунт с этим email уже существует');
    expect(err(await auth.login(email, 'неверный')), 'Неверный email или пароль');
  });

  test('лента: страницы и поиск идут с настоящего сервера', () async {
    final u = await newUser('feed');
    final items = HttpItemRepository(u.api);

    final first = ok(await items.fetchAll(limit: 5));
    expect(first.length, 5);
    final second = ok(await items.fetchAll(page: 2, limit: 5));
    expect(second.first.id, isNot(first.first.id));
    expect(first.every((i) => i.owner.name.isNotEmpty), isTrue);

    final found = ok(await items.fetchAll(search: 'Levi'));
    expect(found, isNotEmpty);
    expect(found.every((i) => i.title.contains('Levi')), isTrue);

    expect(ok(await items.fetchAll(mine: true)), isEmpty); // новый пользователь
  });

  test('полный цикл вещи: create -> fetchById -> update -> delete', () async {
    final u = await newUser('owner');
    final items = HttpItemRepository(u.api);
    final draft = Item.fromJson({
      'id': 0,
      'title': 'Куртка e2e',
      'description': 'Проверка полного цикла',
      'price': 321,
      'size': 'M',
      'condition': 'Отличное',
      'categoryId': 'c1',
      'status': 'available',
      'imageUrl': '',
      'createdAt': '2026-09-29T10:00:00.000Z',
      'owner': {'id': 1, 'name': 'x', 'email': 'x@x.md'},
    });

    final created = ok(await items.create(draft));
    expect(created.id, isNot('0')); // id выдал сервер
    expect(created.status, ItemStatus.available);
    expect(created.price, 321.0);

    expect(ok(await items.fetchAll(mine: true)).map((i) => i.id), [created.id]);
    expect(ok(await items.fetchById(created.id)).title, 'Куртка e2e');

    final changed = ok(await items.update(created.copyWith(status: ItemStatus.sold)));
    expect(changed.status, ItemStatus.sold);

    expect(await items.delete(created.id), isA<Ok<void>>());
    expect(err(await items.fetchById(created.id)), 'Запись не существует');
    expect(err(await items.delete(created.id)), 'Запись не существует');
  });

  test('бронь: сервер меняет статус вещи, повтор отклоняется, отмена возвращает',
      () async {
    final seller = await newUser('seller');
    final buyer = await newUser('buyer');
    final sellerItems = HttpItemRepository(seller.api);
    final buyerItems = HttpItemRepository(buyer.api);
    final buyerReservations = HttpReservationRepository(buyer.api);

    final item = ok(await sellerItems.create(Item.fromJson({
      'id': 0, 'title': 'Платье e2e', 'description': 'Проверка брони',
      'price': 150, 'size': 'S', 'condition': 'Хорошее', 'categoryId': 'c3',
      'status': 'available', 'imageUrl': '',
      'createdAt': '2026-09-29T10:00:00.000Z',
      'owner': {'id': 1, 'name': 'x', 'email': 'x@x.md'},
    })));

    final draft = Reservation(
      id: '',
      status: ReservationStatus.pending,
      createdAt: DateTime.now(),
      item: ok(await buyerItems.fetchById(item.id)),
    );
    final reservation = ok(await buyerReservations.create(draft));
    expect(reservation.status, ReservationStatus.pending);
    expect(reservation.item.status, ItemStatus.reserved);

    expect(err(await buyerReservations.create(draft)), 'Вещь уже недоступна');
    expect(ok(await buyerReservations.fetchAll()).map((r) => r.itemId),
        contains(item.id));

    final cancelled = ok(await buyerReservations
        .update(reservation.copyWith(status: ReservationStatus.cancelled)));
    expect(cancelled.status, ReservationStatus.cancelled);
    expect(cancelled.item.status, ItemStatus.available);
  });

  test('401: мёртвый токен стирается, колбэк корня вызывается', () async {
    SharedPreferences.setMockInitialValues({'auth_token': 'not.a.token'});
    final tokens = TokenStore();
    var notified = 0;
    final api = ApiClient(_base, tokens, onUnauthorized: () => notified++);

    final msg = err(await HttpItemRepository(api).fetchAll());

    expect(msg, 'Сессия истекла - войдите снова');
    expect(await tokens.read(), isNull);
    expect(notified, 1);
  });

  test('остановленный сервер: Err с сообщением про сеть, без исключения', () async {
    SharedPreferences.setMockInitialValues({'auth_token': 'x'});
    final api = ApiClient('http://localhost:1', TokenStore());

    expect(err(await HttpItemRepository(api).fetchAll()),
        'Нет сети - повторите попытку');
  });

  test('загрузка файла: POST /files возвращает относительный путь', () async {
    final u = await newUser('uploader');
    final file = File('${Directory.systemTemp.path}/e2e_photo.png')
      ..writeAsBytesSync(base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='));
    addTearDown(file.deleteSync);

    final url = ok(await FileApi(u.api, _base).upload(file.path));

    expect(url, matches(RegExp(r'^/files/\d+$')));
    final request = await HttpClient().getUrl(Uri.parse('$_base$url'));
    final response = await request.close();
    expect(response.statusCode, 200);
    expect(response.headers.value('content-disposition'), 'attachment');
    await response.drain<void>();
  });
}
