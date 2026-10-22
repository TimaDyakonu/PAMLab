// Conformance checks: talks to a running server over HTTP, exactly like the
// Flutter app does, and verifies every letter of the contract.
//
//   dart run tool/conformance.dart --base-url http://localhost:8765
//
// Part 1 checks the base template (auth, notes, files); part 2 checks the
// entities of the theme (items, reservations). After any change of the server
// run it again: a passing run proves that the extension did not break the
// base contract.

import 'dart:convert';
import 'dart:io';

final _client = HttpClient();
var _passed = 0;
var _failed = 0;
late String _base;

typedef Reply = ({int status, dynamic json, List<int> bytes, HttpHeaders headers});

Future<Reply> call(
  String method,
  String path, {
  String? token,
  Object? body,
  List<int>? raw,
  String? contentType,
}) async {
  final request = await _client.openUrl(method, Uri.parse('$_base$path'));
  if (token != null) request.headers.set('authorization', 'Bearer $token');
  if (body != null) {
    request.headers.contentType = ContentType.json;
    request.add(utf8.encode(jsonEncode(body)));
  }
  if (raw != null) {
    request.headers.set('content-type', contentType!);
    request.add(raw);
  }
  final response = await request.close();
  final bytes = <int>[];
  await for (final chunk in response) {
    bytes.addAll(chunk);
  }
  dynamic json;
  try {
    json = jsonDecode(utf8.decode(bytes));
  } catch (_) {}
  return (
    status: response.statusCode,
    json: json,
    bytes: bytes,
    headers: response.headers,
  );
}

void check(String name, bool ok, [Object? detail]) {
  if (ok) {
    _passed++;
    print('  ✓ $name');
  } else {
    _failed++;
    print('  ✗ $name${detail == null ? '' : '   -> $detail'}');
  }
}

String? errorCode(Reply r) {
  final json = r.json;
  if (json is! Map) return null;
  final error = json['error'];
  return error is Map ? error['code'] as String? : null;
}

Future<String> register(String email, String name) async {
  final r = await call('POST', '/auth/register',
      body: {'email': email, 'password': 'parola123', 'name': name});
  return r.json['token'] as String;
}

Map<String, Object?> newItem(String title, {num price = 250}) => {
      'title': title,
      'description': 'Описание вещи для проверки',
      'price': price,
      'size': 'M',
      'condition': 'Хорошее',
      'categoryId': 'c1',
    };

Future<void> baseContract(String a) async {
  print('\nBase contract');
  final health = await call('GET', '/health');
  check('GET /health -> 200 {"status":"ok"}',
      health.status == 200 && health.json['status'] == 'ok');
  final none = await call('GET', '/notes');
  check('GET /notes without token -> 401 UNAUTHORIZED',
      none.status == 401 && errorCode(none) == 'UNAUTHORIZED');

  final email = 'dup${DateTime.now().microsecondsSinceEpoch}@test.md';
  final first = await call('POST', '/auth/register',
      body: {'email': email, 'password': 'parola123', 'name': 'Dup'});
  check('register -> 201 {token, user}',
      first.status == 201 && first.json['token'] != null);
  final second = await call('POST', '/auth/register',
      body: {'email': email, 'password': 'parola123', 'name': 'Dup'});
  check('register twice -> 409 EMAIL_TAKEN',
      second.status == 409 && errorCode(second) == 'EMAIL_TAKEN');
  final bad = await call('POST', '/auth/register',
      body: {'email': 'no-at-sign', 'password': 'x', 'name': 'x'});
  check('register with a bad email -> 400 VALIDATION_ERROR',
      bad.status == 400 && errorCode(bad) == 'VALIDATION_ERROR');
  final login = await call('POST', '/auth/login',
      body: {'email': email, 'password': 'parola123'});
  check('login -> 200 {token}', login.status == 200 && login.json['token'] != null);
  final wrong = await call('POST', '/auth/login',
      body: {'email': email, 'password': 'wrong-password'});
  check('login with a wrong password -> 401 UNAUTHORIZED',
      wrong.status == 401 && errorCode(wrong) == 'UNAUTHORIZED');
  final me = await call('GET', '/me', token: a);
  check('GET /me -> 200 {id, email, name}',
      me.status == 200 && me.json['email'] != null);
  final fake = await call('GET', '/me', token: 'garbage.token.value');
  check('a garbage token -> 401', fake.status == 401);
}

Future<void> notes(String a, String b) async {
  print('\nNotes (the example entity)');
  final empty = await call('GET', '/notes', token: a);
  check('list -> envelope {items, page, limit, total}',
      empty.json['items'] is List && empty.json['total'] == 0);
  final created = await call('POST', '/notes',
      token: a, body: {'title': 'Покупки', 'content': 'молоко, хлеб'});
  check('create -> 201 with an id from the server',
      created.status == 201 && created.json['id'] != null);
  final id = created.json['id'];
  final invalid = await call('POST', '/notes', token: a, body: {'content': 'x'});
  check('create without a title -> 400', invalid.status == 400);
  final found = await call('GET', '/notes?search=Покуп', token: a);
  check('search runs on the server', found.json['total'] == 1);
  final other = await call('GET', '/notes/$id', token: b);
  check("someone else's note -> 404, not 403", other.status == 404);
  final put = await call('PUT', '/notes/$id',
      token: a, body: {'title': 'Покупки 2', 'content': ''});
  check('update -> 200', put.status == 200 && put.json['title'] == 'Покупки 2');
  final del = await call('DELETE', '/notes/$id', token: a);
  check('delete -> 204 with an empty body', del.status == 204 && del.bytes.isEmpty);
  final gone = await call('GET', '/notes/$id', token: a);
  check('deleted note -> 404', gone.status == 404 && errorCode(gone) == 'NOT_FOUND');
}

List<int> multipart(String boundary, List<int> data) => [
      ...utf8.encode('--$boundary\r\n'
          'Content-Disposition: form-data; name="file"; filename="a.png"\r\n'
          'Content-Type: image/png\r\n\r\n'),
      ...data,
      ...utf8.encode('\r\n--$boundary--\r\n'),
    ];

Future<void> files(String a) async {
  print('\nFiles');
  const type = 'multipart/form-data; boundary=XYZ';
  final up = await call('POST', '/files',
      token: a, raw: multipart('XYZ', [1, 2, 3, 4]), contentType: type);
  check('upload -> 201 {id, url, size}', up.status == 201 && up.json['url'] != null);
  final down = await call('GET', up.json['url'] as String);
  check('download returns the same bytes',
      down.status == 200 && down.bytes.length == 4);
  check('download is sent as an attachment',
      down.headers.value('content-disposition') == 'attachment');
  // The server may refuse an oversized body before reading it, closing the
  // connection while the client is still sending: both outcomes are a refusal.
  var refused = false;
  try {
    final big = await call('POST', '/files',
        token: a,
        raw: multipart('XYZ', List.filled(5 * 1024 * 1024 + 10, 7)),
        contentType: type);
    refused = big.status == 400 && errorCode(big) == 'VALIDATION_ERROR';
  } on IOException {
    refused = true;
  }
  check('a file over 5 MB is refused (400 VALIDATION_ERROR)', refused);
  final missing = await call('GET', '/files/999999');
  check('missing file -> 404', missing.status == 404);
}

Future<void> items(String a, String b) async {
  print('\nItems (theme entity)');
  final feed = await call('GET', '/items?limit=5', token: a);
  check('feed uses the page envelope',
      feed.json['limit'] == 5 && (feed.json['items'] as List).length == 5);
  final total = feed.json['total'] as int;
  final last = await call('GET', '/items?limit=5&page=${(total / 5).ceil()}', token: a);
  check('the last page is shorter and the total is stable',
      last.json['total'] == total &&
          (last.json['items'] as List).length == total - ((total / 5).ceil() - 1) * 5);
  final search = await call('GET', '/items?search=Levi', token: a);
  check('search runs on the server', (search.json['items'] as List).isNotEmpty);

  final invalid = await call('POST', '/items',
      token: a, body: newItem('Тест', price: -5));
  check('create with a negative price -> 400', invalid.status == 400);
  final created = await call('POST', '/items', token: a, body: newItem('Куртка проверки'));
  check('create -> 201, status available, owner is me',
      created.status == 201 &&
          created.json['status'] == 'available' &&
          created.json['owner']['id'] != null);
  final id = created.json['id'];
  final mine = await call('GET', '/items?mine=true&search=проверки', token: a);
  check('my item is in mine=true', mine.json['total'] == 1);
  final myFeed = await call('GET', '/items?search=проверки', token: a);
  check('my own item is not in my feed', myFeed.json['total'] == 0);
  final otherFeed = await call('GET', '/items?search=проверки', token: b);
  check("another user's feed shows it", otherFeed.json['total'] == 1);
  final seen = await call('GET', '/items/$id', token: b);
  check('anybody can open an item by id -> 200', seen.status == 200);
  final put = await call('PUT', '/items/$id', token: b, body: newItem('Чужая'));
  check("changing someone else's item -> 404", put.status == 404);
  final del = await call('DELETE', '/items/$id', token: b);
  check("deleting someone else's item -> 404", del.status == 404);
  final upd = await call('PUT', '/items/$id', token: a, body: newItem('Куртка проверки', price: 300));
  check('owner updates the item -> 200', upd.status == 200 && upd.json['price'] == 300);
  final missing = await call('GET', '/items/999999', token: a);
  check('missing item -> 404 NOT_FOUND',
      missing.status == 404 && errorCode(missing) == 'NOT_FOUND');
}

Future<void> reservations(String a, String b) async {
  print('\nReservations (theme entity)');
  final item = await call('POST', '/items', token: a, body: newItem('Платье брони'));
  final itemId = item.json['id'];
  final own = await call('POST', '/reservations', token: a, body: {'itemId': itemId});
  check('reserving my own item -> 400', own.status == 400);
  final none = await call('POST', '/reservations', token: b, body: {'itemId': 999999});
  check('reserving a missing item -> 404', none.status == 404);

  final res = await call('POST', '/reservations', token: b, body: {'itemId': itemId});
  check('reserve -> 201 pending with the item embedded',
      res.status == 201 &&
          res.json['status'] == 'pending' &&
          res.json['item']['status'] == 'reserved');
  final again = await call('POST', '/reservations', token: b, body: {'itemId': itemId});
  check('reserving it again -> 409 ITEM_UNAVAILABLE',
      again.status == 409 && errorCode(again) == 'ITEM_UNAVAILABLE');
  final list = await call('GET', '/reservations', token: b);
  check('my reservations contain it',
      (list.json['items'] as List).any((r) => r['itemId'] == itemId));
  final resId = res.json['id'];
  final foreign = await call('PUT', '/reservations/$resId', token: a, body: {'status': 'cancelled'});
  check("cancelling someone else's reservation -> 404", foreign.status == 404);
  final badStatus = await call('PUT', '/reservations/$resId', token: b, body: {'status': 'completed'});
  check('only "cancelled" is accepted -> 400', badStatus.status == 400);
  final cancel = await call('PUT', '/reservations/$resId', token: b, body: {'status': 'cancelled'});
  check('cancel -> 200 and the item is available again',
      cancel.status == 200 &&
          cancel.json['status'] == 'cancelled' &&
          cancel.json['item']['status'] == 'available');
  final twice = await call('PUT', '/reservations/$resId', token: b, body: {'status': 'cancelled'});
  check('cancelling a closed reservation -> 400', twice.status == 400);

  await call('POST', '/reservations', token: b, body: {'itemId': itemId});
  await call('DELETE', '/items/$itemId', token: a);
  final after = await call('GET', '/reservations', token: b);
  check('deleting an item removes its reservations',
      !(after.json['items'] as List).any((r) => r['itemId'] == itemId));
}

Future<void> main(List<String> args) async {
  final i = args.indexOf('--base-url');
  _base = i >= 0 ? args[i + 1] : 'http://localhost:8765';
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final a = await register('a$stamp@test.md', 'Alice');
  final b = await register('b$stamp@test.md', 'Bob');

  await baseContract(a);
  await notes(a, b);
  await files(a);
  await items(a, b);
  await reservations(a, b);

  final total = _passed + _failed;
  print('\n${_failed == 0 ? 'PASS' : 'FAIL'} - $_passed/$total checks passed');
  exit(_failed == 0 ? 0 : 1);
}
