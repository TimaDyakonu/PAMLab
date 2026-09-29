// models/items_model.dart — состояние списка вещей + триада «грузится /
// данные / ошибка». Модель не держит список «ради него самого»: она просит
// его у хранилища, которое входит через конструктор. Чистый Dart.
import 'package:flutter/foundation.dart';
import '../data/item.dart';
import '../data/item_repository.dart';
import '../data/result.dart';
import '../data/user.dart';

class ItemsModel extends ChangeNotifier {
  ItemsModel(this._repository); // простой DI: хранилище — в конструктор

  final ItemRepository _repository; // тип — ИНТЕРФЕЙС, а не mock!

  bool _loading = false;
  String? _error;
  List<Item> _items = const [];

  bool get isLoading => _loading;
  String? get error => _error;
  List<Item> get items => List.unmodifiable(_items);

  /// Вещь по id из загруженного списка; null — если такой нет.
  Item? byId(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Лента: вещи других пользователей.
  List<Item> feedFor(User user) =>
      _items.where((i) => i.owner.id != user.id).toList();

  /// Объявления самого пользователя.
  List<Item> ownedBy(User user) =>
      _items.where((i) => i.owner.id == user.id).toList();

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners(); // подписанные экраны входят в состояние «грузится»

    switch (await _repository.fetchAll()) {
      case Ok(:final value):
        _items = value;
      case Err(:final msg):
        _error = msg;
    }
    _loading = false;
    notifyListeners(); // …и выходят: с товаром или с ошибкой — никогда молча
  }

  // Мутации: null при успехе, сообщение об ошибке при провале — та же логика,
  // что у validator. При ошибке состояние не тронуто: экран решает, что показать.

  Future<String?> add(Item draft) async {
    switch (await _repository.create(draft)) {
      case Ok(:final value):
        _items = [value, ..._items]; // новая вещь — первой, с id от хранилища
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  Future<String?> update(Item item) async {
    switch (await _repository.update(item)) {
      case Ok(:final value):
        _items = [for (final i in _items) i.id == value.id ? value : i];
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  Future<String?> remove(String id) async {
    switch (await _repository.delete(id)) {
      case Ok():
        _items = [for (final i in _items) if (i.id != id) i];
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }
}
