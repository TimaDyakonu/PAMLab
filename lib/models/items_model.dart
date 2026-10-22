// models/items_model.dart: состояние вещей + триада «грузится / данные / ошибка».
// Модель не держит список «ради него самого»: она просит его у хранилища,
// которое входит через конструктор. Чистый Dart.
//
// Вещи с сервера приходят порциями двух разных запросов: лента (страницами,
// с поиском) и «мои объявления». Поэтому все вещи лежат в одном кэше по id,
// а лента и «мои» хранят только списки идентификаторов.
import 'package:flutter/foundation.dart';
import '../data/item.dart';
import '../data/item_repository.dart';
import '../data/result.dart';

class ItemsModel extends ChangeNotifier {
  ItemsModel(this._repository, {this.userId, this.pageSize = 20});

  final ItemRepository _repository; // тип: ИНТЕРФЕЙС, а не конкретный источник
  final String? userId; // модель принадлежит одному пользователю
  final int pageSize;

  final Map<String, Item> _cache = {};

  // --- лента ---
  List<String> _feedIds = const [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  String? _moreError;
  String? _search;
  int _page = 1;
  bool _hasMore = false;

  bool get isLoading => _loading;
  String? get error => _error;
  String? get search => _search;

  /// Полная страница означает, что дальше, возможно, есть ещё.
  bool get hasMore => _hasMore;
  String? get loadMoreError => _moreError;
  List<Item> get feed =>
      List.unmodifiable([for (final id in _feedIds) _cache[id]!]);

  // --- мои объявления ---
  List<String> _mineIds = const [];
  bool _mineLoading = false;
  String? _mineError;

  bool get isMineLoading => _mineLoading;
  String? get mineError => _mineError;
  List<Item> get mine =>
      List.unmodifiable([for (final id in _mineIds) _cache[id]!]);

  /// Вещь из кэша по id; null, если её никто не загружал.
  Item? byId(String id) => _cache[id];

  /// Первая страница ленты. search == null оставляет прежний фильтр (так
  /// «Повторить» сохраняет поиск), пустая строка его сбрасывает.
  Future<void> load({String? search}) async {
    _search = search ?? _search;
    _page = 1;
    _loading = true;
    _error = null;
    _moreError = null;
    notifyListeners(); // подписанные экраны входят в состояние «грузится»

    final result = await _repository.fetchAll(
      page: 1,
      limit: pageSize,
      search: _search,
    );
    switch (result) {
      case Ok(:final value):
        _feedIds = _remember(value);
        _hasMore = value.length == pageSize;
      case Err(:final msg):
        _error = msg;
    }
    _loading = false;
    notifyListeners(); // ...и выходят: с вещами или с ошибкой, никогда молча
  }

  /// Следующая страница ленты приклеивается к списку.
  /// Вызывается из itemBuilder, то есть в разгар build: синхронный
  /// notifyListeners() здесь бросил бы «setState() called during build»,
  /// поэтому _loadingMore ставится без извещения (спиннер хвоста уже на экране
  /// благодаря hasMore), а guard не даёт запросить одну страницу дважды.
  Future<void> loadMore() async {
    if (_loadingMore || _loading || !_hasMore || _moreError != null) return;
    _loadingMore = true;

    final result = await _repository.fetchAll(
      page: _page + 1,
      limit: pageSize,
      search: _search,
    );
    switch (result) {
      case Ok(:final value):
        _page += 1;
        final known = _feedIds.toSet();
        _feedIds = [
          ..._feedIds,
          for (final id in _remember(value))
            if (!known.contains(id)) id,
        ];
        _hasMore = value.length == pageSize;
      case Err(:final msg):
        _moreError = msg;
    }
    _loadingMore = false;
    notifyListeners();
  }

  /// Повтор подгрузки хвоста после ошибки.
  Future<void> retryLoadMore() async {
    _moreError = null;
    notifyListeners();
    await loadMore();
  }

  Future<void> loadMine() async {
    _mineLoading = true;
    _mineError = null;
    notifyListeners();

    final result = await _repository.fetchAll(limit: 100, mine: true);
    switch (result) {
      case Ok(:final value):
        _mineIds = _remember(value);
      case Err(:final msg):
        _mineError = msg;
    }
    _mineLoading = false;
    notifyListeners();
  }

  /// Подменить вещь новой версией (например, после брони сервер вернул вещь
  /// с новым статусом). Сетевого запроса нет: сервер уже всё сделал.
  void apply(Item item) {
    if (!_cache.containsKey(item.id)) return;
    _cache[item.id] = item;
    notifyListeners();
  }

  // Мутации: null при успехе, сообщение об ошибке при провале, та же логика,
  // что у validator. При ошибке состояние не тронуто: экран решает, что показать.

  Future<String?> add(Item draft) async {
    switch (await _repository.create(draft)) {
      case Ok(:final value):
        _cache[value.id] = value; // id выдал сервер
        _mineIds = [value.id, ..._mineIds];
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  Future<String?> update(Item item) async {
    switch (await _repository.update(item)) {
      case Ok(:final value):
        _cache[value.id] = value;
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  Future<String?> remove(String id) async {
    switch (await _repository.delete(id)) {
      case Ok():
        _cache.remove(id);
        _feedIds = [for (final i in _feedIds) if (i != id) i];
        _mineIds = [for (final i in _mineIds) if (i != id) i];
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  /// Кладёт вещи в кэш и возвращает их идентификаторы по порядку.
  List<String> _remember(List<Item> items) {
    for (final item in items) {
      _cache[item.id] = item;
    }
    return [for (final item in items) item.id];
  }
}
