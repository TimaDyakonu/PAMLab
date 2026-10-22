// Fake-репозитории для тестов: хранилище в памяти, которое ведёт себя как
// сервер L5 (страницы, поиск, «мои», бронь меняет статус вещи), и переключатель
// отказа сети. Живут только в test/: в приложении источник это http.
import 'package:second_hand_market/data/item.dart';
import 'package:second_hand_market/data/item_repository.dart';
import 'package:second_hand_market/data/reservation.dart';
import 'package:second_hand_market/data/reservation_repository.dart';
import 'package:second_hand_market/data/result.dart';

import 'fake_data.dart';

const offlineMessage = 'Нет сети - повторите попытку';

class FakeItemRepository implements ItemRepository {
  FakeItemRepository({List<Item>? items, this.currentUserId = 'u1'})
      : _items = List.of(items ?? fakeItems);

  final String currentUserId;
  final List<Item> _items;
  int _nextId = 1000;

  /// true: любой вызов проваливается, как при остановленном сервере.
  bool fail = false;

  /// Сколько раз спросили страницы ленты (для проверки «одну страницу дважды
  /// не просят»).
  final List<int> requestedPages = [];

  Item? find(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    return index < 0 ? null : _items[index];
  }

  void replace(Item item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index >= 0) _items[index] = item;
  }

  @override
  Future<Result<List<Item>>> fetchAll({
    int page = 1,
    int limit = 20,
    String? search,
    bool mine = false,
  }) async {
    if (fail) return Err(offlineMessage);
    if (!mine) requestedPages.add(page);
    final needle = (search ?? '').toLowerCase();
    final matching = [
      for (final item in _items)
        if ((item.owner.id == currentUserId) == mine &&
            (item.title.toLowerCase().contains(needle) ||
                item.description.toLowerCase().contains(needle)))
          item,
    ];
    final from = (page - 1) * limit;
    if (from >= matching.length) return const Ok([]);
    final to = (from + limit).clamp(0, matching.length);
    return Ok(matching.sublist(from, to));
  }

  @override
  Future<Result<Item>> fetchById(String id) async {
    if (fail) return Err(offlineMessage);
    final item = find(id);
    return item == null ? Err('Запись не существует') : Ok(item);
  }

  @override
  Future<Result<Item>> create(Item item) async {
    if (fail) return Err(offlineMessage);
    final created = item.copyWith(id: 'i${_nextId++}');
    _items.insert(0, created);
    return Ok(created);
  }

  @override
  Future<Result<Item>> update(Item item) async {
    if (fail) return Err(offlineMessage);
    if (find(item.id) == null) return Err('Запись не существует');
    replace(item);
    return Ok(item);
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (fail) return Err(offlineMessage);
    if (find(id) == null) return Err('Запись не существует');
    _items.removeWhere((i) => i.id == id);
    return const Ok(null);
  }
}

class FakeReservationRepository implements ReservationRepository {
  FakeReservationRepository(this._items, {List<Reservation>? reservations})
      : _reservations = List.of(reservations ?? fakeReservations);

  final FakeItemRepository _items;
  final List<Reservation> _reservations;
  int _nextId = 1000;

  bool fail = false;

  @override
  Future<Result<List<Reservation>>> fetchAll({
    int page = 1,
    int limit = 20,
  }) async {
    if (fail) return Err(offlineMessage);
    return Ok(List.of(_reservations));
  }

  /// Как сервер: бронь и статус вещи меняются вместе, в ответе вещь свежая.
  @override
  Future<Result<Reservation>> create(Reservation draft) async {
    if (fail) return Err(offlineMessage);
    final item = _items.find(draft.itemId);
    if (item == null) return Err('Запись не существует');
    if (item.status != ItemStatus.available) return Err('Вещь уже недоступна');
    final reserved = item.copyWith(status: ItemStatus.reserved);
    _items.replace(reserved);
    final created = Reservation(
      id: 'r${_nextId++}',
      status: ReservationStatus.pending,
      createdAt: DateTime.now(),
      item: reserved,
    );
    _reservations.insert(0, created);
    return Ok(created);
  }

  @override
  Future<Result<Reservation>> update(Reservation r) async {
    if (fail) return Err(offlineMessage);
    final index = _reservations.indexWhere((x) => x.id == r.id);
    if (index < 0) return Err('Запись не существует');
    final item = _items.find(r.itemId)!;
    final freed = item.status == ItemStatus.reserved
        ? item.copyWith(status: ItemStatus.available)
        : item;
    _items.replace(freed);
    final updated = Reservation(
      id: r.id,
      status: r.status,
      createdAt: r.createdAt,
      item: freed,
    );
    _reservations[index] = updated;
    return Ok(updated);
  }
}
