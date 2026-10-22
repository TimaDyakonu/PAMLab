// models/reservations_model.dart: брони текущего пользователя («Мои покупки»)
// с той же триадой состояний. Второй ChangeNotifier темы: у второй пишущей
// сущности свое хранилище и своя модель.
import 'package:flutter/foundation.dart';
import '../data/item.dart';
import '../data/reservation.dart';
import '../data/reservation_repository.dart';
import '../data/result.dart';

class ReservationsModel extends ChangeNotifier {
  ReservationsModel(this._repository, {this.userId, this.onItemChanged});

  final ReservationRepository _repository;
  final String? userId; // модель принадлежит одному пользователю

  /// Бронь меняет статус вещи на сервере и возвращает вещь уже обновлённой.
  /// Модель отдаёт её наружу, не зная, кто ею интересуется (корень связывает
  /// это с ItemsModel).
  final void Function(Item item)? onItemChanged;

  bool _loading = false;
  String? _error;
  List<Reservation> _reservations = const [];

  bool get isLoading => _loading;
  String? get error => _error;
  List<Reservation> get reservations => List.unmodifiable(_reservations);

  int get completedCount => _reservations
      .where((r) => r.status == ReservationStatus.completed)
      .length;

  /// Активная (ожидает ответа / подтверждена) бронь этой вещи; null, если нет.
  Reservation? activeFor(String itemId) {
    for (final r in _reservations) {
      if (r.itemId == itemId && r.isActive) return r;
    }
    return null;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    switch (await _repository.fetchAll(limit: 100)) {
      case Ok(:final value):
        _reservations = value;
      case Err(:final msg):
        _error = msg;
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> reserve(Item item) async {
    final draft = Reservation(
      id: '', // настоящий id даст сервер
      status: ReservationStatus.pending,
      createdAt: DateTime.now(),
      item: item,
    );
    switch (await _repository.create(draft)) {
      case Ok(:final value):
        _reservations = [value, ..._reservations];
        onItemChanged?.call(value.item);
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  Future<String?> cancel(Reservation reservation) async {
    final cancelled = reservation.copyWith(status: ReservationStatus.cancelled);
    switch (await _repository.update(cancelled)) {
      case Ok(:final value):
        _reservations = [
          for (final r in _reservations) r.id == value.id ? value : r
        ];
        onItemChanged?.call(value.item);
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }
}
