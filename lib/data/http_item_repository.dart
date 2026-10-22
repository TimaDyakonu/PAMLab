// data/http_item_repository.dart: вторая реализация интерфейса L4, на http.
// Каждый метод отображается на свой маршрут контракта (таблица в L4); три слоя
// отказа живут в ApiClient, поэтому здесь только маршрут и разбор ответа.
import 'api_client.dart';
import 'item.dart';
import 'item_repository.dart';
import 'result.dart';

class HttpItemRepository implements ItemRepository {
  HttpItemRepository(this._api);

  final ApiClient _api;

  Item _item(dynamic json) => Item.fromJson(json as Map<String, dynamic>);

  @override
  Future<Result<List<Item>>> fetchAll({
    int page = 1,
    int limit = 20,
    String? search,
    bool mine = false,
  }) {
    return _api.send(
      'GET',
      '/items',
      ok: {200},
      query: {
        'page': '$page',
        'limit': '$limit',
        if (search != null && search.isNotEmpty) 'search': search,
        if (mine) 'mine': 'true',
      },
      // конверт {items, page, limit, total}: список лежит внутри
      parse: (json) => [
        for (final e in (json as Map<String, dynamic>)['items'] as List)
          _item(e),
      ],
    );
  }

  @override
  Future<Result<Item>> fetchById(String id) =>
      _api.send('GET', '/items/$id', ok: {200}, parse: _item);

  @override
  Future<Result<Item>> create(Item item) =>
      _api.send('POST', '/items', ok: {201}, body: item.toJson(), parse: _item);

  @override
  Future<Result<Item>> update(Item item) => _api.send(
        'PUT',
        '/items/${item.id}',
        ok: {200},
        body: {...item.toJson(), 'status': item.status.name},
        parse: _item,
      );

  @override
  Future<Result<void>> delete(String id) {
    // 204: тело ПУСТОЕ, jsonDecode на нём не вызывается (ловушка C8)
    return _api.send('DELETE', '/items/$id', ok: {204}, parse: (_) {});
  }
}
