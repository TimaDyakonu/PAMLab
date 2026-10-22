// data/http_reservation_repository.dart: брони по http.
// Сервер сам меняет статус вещи вместе с бронью в одной транзакции, а в ответе
// приходит бронь с уже обновлённой вещью.
import 'api_client.dart';
import 'reservation.dart';
import 'reservation_repository.dart';
import 'result.dart';

class HttpReservationRepository implements ReservationRepository {
  HttpReservationRepository(this._api);

  final ApiClient _api;

  Reservation _reservation(dynamic json) =>
      Reservation.fromJson(json as Map<String, dynamic>);

  @override
  Future<Result<List<Reservation>>> fetchAll({int page = 1, int limit = 20}) {
    return _api.send(
      'GET',
      '/reservations',
      ok: {200},
      query: {'page': '$page', 'limit': '$limit'},
      parse: (json) => [
        for (final e in (json as Map<String, dynamic>)['items'] as List)
          _reservation(e),
      ],
    );
  }

  @override
  Future<Result<Reservation>> create(Reservation draft) => _api.send(
        'POST',
        '/reservations',
        ok: {201},
        body: {'itemId': draft.itemId},
        parse: _reservation,
      );

  @override
  Future<Result<Reservation>> update(Reservation r) => _api.send(
        'PUT',
        '/reservations/${r.id}',
        ok: {200},
        body: {'status': r.status.name},
        parse: _reservation,
      );
}
