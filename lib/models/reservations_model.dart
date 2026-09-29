// models/reservations_model.dart — брони текущего пользователя («Мои покупки»)
// с той же триадой состояний. Второй ChangeNotifier темы: у второй пишущей
// сущности — своё хранилище и своя модель.
import 'package:flutter/foundation.dart';
import '../data/reservation.dart';
import '../data/reservation_repository.dart';
import '../data/result.dart';

class ReservationsModel extends ChangeNotifier {
  ReservationsModel(this._repository);

  final ReservationRepository _repository;

  bool _loading = false;
  String? _error;
  List<Reservation> _reservations = const [];

  bool get isLoading => _loading;
  String? get error => _error;
  List<Reservation> get reservations => List.unmodifiable(_reservations);

  int get completedCount =>
      _reservations.where((r) => r.status == ReservationStatus.completed).length;

  /// Активная (ожидает ответа / подтверждена) бронь этой вещи; null — нет.
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

    switch (await _repository.fetchAll()) {
      case Ok(:final value):
        _reservations = value;
      case Err(:final msg):
        _error = msg;
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> reserve(String itemId, String buyerId) async {
    final draft = Reservation(
        '', itemId, buyerId, ReservationStatus.pending, DateTime.now());
    switch (await _repository.create(draft)) {
      case Ok(:final value):
        _reservations = [value, ..._reservations];
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
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }
}
