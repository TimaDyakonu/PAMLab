// data/item_repository.dart — контракт: ЧТО можно просить, а не КАК.
// На L5 каждый метод отображается один-к-одному на REST-контракт backend-а.
import 'item.dart';
import 'result.dart';

abstract class ItemRepository {
  Future<Result<List<Item>>> fetchAll(); //         L5: GET    /items
  Future<Result<Item>> fetchById(String id); //     L5: GET    /items/{id}
  Future<Result<Item>> create(Item item); //        L5: POST   /items
  Future<Result<Item>> update(Item item); //        L5: PUT    /items/{id}
  Future<Result<void>> delete(String id); //        L5: DELETE /items/{id}
}
