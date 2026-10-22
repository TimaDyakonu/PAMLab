import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:second_hand_market/data/api_client.dart';
import 'package:second_hand_market/data/http_reservation_repository.dart';
import 'package:second_hand_market/data/item.dart';
import 'package:second_hand_market/data/reservation.dart';
import 'package:second_hand_market/data/result.dart';
import 'package:second_hand_market/data/token_store.dart';

import '../support/test_app.dart';

Map<String, dynamic> itemJson(String status) => {
      'id': 7,
      'title': 'Вещь 7',
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

Map<String, dynamic> reservationJson(String status, String itemStatus) => {
      'id': 3,
      'itemId': 7,
      'status': status,
      'createdAt': '2026-09-20T10:00:00.000Z',
      'item': itemJson(itemStatus),
    };

HttpReservationRepository repoFor(
        Future<http.Response> Function(http.Request) h) =>
    HttpReservationRepository(
        ApiClient('http://x', TokenStore(), client: MockClient(h)));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'auth_token': 'T'}));

  test('fetchAll: GET /reservations, у брони есть вложенная вещь', () async {
    late http.Request seen;
    final repo = repoFor((r) async {
      seen = r;
      return jsonReply({
        'items': [reservationJson('pending', 'reserved')],
        'page': 1,
        'limit': 20,
        'total': 1,
      }, 200);
    });

    final result = await repo.fetchAll();

    expect(seen.url.path, '/reservations');
    final reservation = (result as Ok<List<Reservation>>).value.single;
    expect(reservation.id, '3');
    expect(reservation.status, ReservationStatus.pending);
    expect(reservation.item.title, 'Вещь 7');
    expect(reservation.item.status, ItemStatus.reserved);
  });

  test('create: POST /reservations {itemId}, в ответе вещь уже «reserved»',
      () async {
    late http.Request seen;
    final repo = repoFor((r) async {
      seen = r;
      return jsonReply(reservationJson('pending', 'reserved'), 201);
    });
    final draft = Reservation(
      id: '',
      status: ReservationStatus.pending,
      createdAt: DateTime.now(),
      item: Item.fromJson(itemJson('available')),
    );

    final result = await repo.create(draft);

    expect(seen.method, 'POST');
    expect(jsonDecode(seen.body), {'itemId': '7'});
    expect((result as Ok<Reservation>).value.item.status, ItemStatus.reserved);
  });

  test('create занятой вещи: 409 ITEM_UNAVAILABLE -> русское сообщение', () async {
    final repo = repoFor((_) async => jsonReply({
          'error': {'code': 'ITEM_UNAVAILABLE', 'message': 'x'},
        }, 409));
    final draft = Reservation(
      id: '',
      status: ReservationStatus.pending,
      createdAt: DateTime.now(),
      item: Item.fromJson(itemJson('reserved')),
    );

    final result = await repo.create(draft);

    expect((result as Err).msg, 'Вещь уже недоступна');
  });

  test('update: PUT /reservations/{id} со статусом cancelled', () async {
    late http.Request seen;
    final repo = repoFor((r) async {
      seen = r;
      return jsonReply(reservationJson('cancelled', 'available'), 200);
    });
    final active = Reservation.fromJson(reservationJson('pending', 'reserved'));

    final result = await repo
        .update(active.copyWith(status: ReservationStatus.cancelled));

    expect(seen.method, 'PUT');
    expect(seen.url.path, '/reservations/3');
    expect(jsonDecode(seen.body), {'status': 'cancelled'});
    expect((result as Ok<Reservation>).value.item.status, ItemStatus.available);
  });
}
