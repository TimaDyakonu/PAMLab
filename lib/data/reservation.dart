// data/reservation.dart: вторая пишущая сущность темы: бронь вещи.
// С сервера бронь приходит вместе с вещью (поле item), поэтому экрану покупок
// не нужно искать вещь отдельно.
import 'item.dart';

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
  final ReservationStatus status;
  final DateTime createdAt;
  final Item item;

  const Reservation({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.item,
  });

  String get itemId => item.id;

  /// Активная бронь ещё держит вещь за покупателем.
  bool get isActive =>
      status == ReservationStatus.pending ||
      status == ReservationStatus.confirmed;

  /// Граница JSON (L5).
  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
        id: '${json['id']}',
        status: ReservationStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        item: Item.fromJson(json['item'] as Map<String, dynamic>),
      );

  Reservation copyWith({String? id, ReservationStatus? status}) => Reservation(
        id: id ?? this.id,
        status: status ?? this.status,
        createdAt: createdAt,
        item: item,
      );
}
