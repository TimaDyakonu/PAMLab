// data/item_repository.dart — контракт: ЧТО можно просить, а не КАК.
// На L5 каждый метод отображается один-к-одному на REST-контракт backend-а.
import 'item.dart';
import 'result.dart';

abstract class ItemRepository {
  /// Интерфейс растёт СОВМЕСТИМО: старый вызов fetchAll() компилируется как
  /// раньше, новые возможности контракта приходят опциональными параметрами.
  /// mine: true - мои объявления, false - лента (вещи других пользователей).
  Future<Result<List<Item>>> fetchAll({
    int page = 1,
    int limit = 20,
    String? search,
    bool mine = false,
  }); //                                           L5: GET    /items
  Future<Result<Item>> fetchById(String id); //     L5: GET    /items/{id}
  Future<Result<Item>> create(Item item); //        L5: POST   /items
  Future<Result<Item>> update(Item item); //        L5: PUT    /items/{id}
  Future<Result<void>> delete(String id); //        L5: DELETE /items/{id}
}
