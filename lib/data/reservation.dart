// data/reservation.dart — вторая пишущая сущность темы: бронь вещи.

/// Статус брони с точки зрения покупателя.
enum ReservationStatus {
  pending('Ожидает ответа'),
  confirmed('Подтверждена'),
  completed('Завершена'),
  cancelled('Отменена');

  final String label;
  const ReservationStatus(this.label);
}

class Reservation {
  final String id;
  final String itemId;
  final String buyerId;
  final ReservationStatus status;
  final DateTime createdAt;

  const Reservation(
      this.id, this.itemId, this.buyerId, this.status, this.createdAt);

  /// Активная бронь ещё держит вещь за покупателем.
  bool get isActive =>
      status == ReservationStatus.pending ||
      status == ReservationStatus.confirmed;

  Reservation copyWith({String? id, ReservationStatus? status}) =>
      Reservation(
          id ?? this.id, itemId, buyerId, status ?? this.status, createdAt);
}
