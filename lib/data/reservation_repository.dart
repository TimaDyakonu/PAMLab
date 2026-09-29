// data/reservation_repository.dart — контракт хранилища броней:
// вторая пишущая сущность темы, поэтому второй repository по тому же шаблону.
import 'reservation.dart';
import 'result.dart';

abstract class ReservationRepository {
  Future<Result<List<Reservation>>> fetchAll(); //          L5: GET /reservations
  Future<Result<Reservation>> create(Reservation draft); // L5: POST /reservations
  Future<Result<Reservation>> update(Reservation r); //     L5: PUT /reservations/{id}
}
