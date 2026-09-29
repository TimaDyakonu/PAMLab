// data/mock_reservation_repository.dart — хранилище броней в памяти.
import 'mock_data.dart';
import 'mock_network.dart';
import 'reservation.dart';
import 'reservation_repository.dart';
import 'result.dart';

class MockReservationRepository implements ReservationRepository {
  MockReservationRepository(this._network);

  final MockNetwork _network;
  final List<Reservation> _reservations = List.of(mockReservations);
  int _nextId = 1000;

  @override
  Future<Result<List<Reservation>>> fetchAll() async {
    await _network.delay();
    if (_network.simulateError) return const Err(MockNetwork.errMessage);
    return Ok(List.of(_reservations));
  }

  @override
  Future<Result<Reservation>> create(Reservation draft) async {
    await _network.delay();
    if (_network.simulateError) return const Err(MockNetwork.errMessage);
    final created = draft.copyWith(id: 'r${_nextId++}');
    _reservations.add(created);
    return Ok(created);
  }

  @override
  Future<Result<Reservation>> update(Reservation r) async {
    await _network.delay();
    if (_network.simulateError) return const Err(MockNetwork.errMessage);
    final index = _reservations.indexWhere((x) => x.id == r.id);
    if (index < 0) return const Err('Брони не существует');
    _reservations[index] = r;
    return Ok(r);
  }
}
