// data/mock_item_repository.dart — хранилище в памяти, с повадками сети.
// На L5 рядом появится вариант на http, экраны его не заметят.
import 'item.dart';
import 'item_repository.dart';
import 'mock_data.dart';
import 'mock_network.dart';
import 'result.dart';

class MockItemRepository implements ItemRepository {
  MockItemRepository(this._network);

  final MockNetwork _network;
  final List<Item> _items = List.of(mockItems); // seed из L2
  int _nextId = 1000; // выше любого id из seed-а

  static const _errNotFound = 'Вещи не существует';

  @override
  Future<Result<List<Item>>> fetchAll() async {
    await _network.delay();
    if (_network.simulateError) return const Err(MockNetwork.errMessage);
    return Ok(List.of(_items)); // копия — внутренность не отдаётся из рук
  }

  @override
  Future<Result<Item>> fetchById(String id) async {
    await _network.delay();
    if (_network.simulateError) return const Err(MockNetwork.errMessage);
    final index = _items.indexWhere((i) => i.id == id);
    if (index < 0) return const Err(_errNotFound); // «404» mock-а
    return Ok(_items[index]);
  }

  @override
  Future<Result<Item>> create(Item item) async {
    await _network.delay();
    if (_network.simulateError) return const Err(MockNetwork.errMessage);
    final created = item.copyWith(id: 'i${_nextId++}'); // id даёт ХРАНИЛИЩЕ
    _items.add(created);
    return Ok(created);
  }

  @override
  Future<Result<Item>> update(Item item) async {
    await _network.delay();
    if (_network.simulateError) return const Err(MockNetwork.errMessage);
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index < 0) return const Err(_errNotFound);
    _items[index] = item;
    return Ok(item);
  }

  @override
  Future<Result<void>> delete(String id) async {
    await _network.delay();
    if (_network.simulateError) return const Err(MockNetwork.errMessage);
    final index = _items.indexWhere((i) => i.id == id);
    if (index < 0) return const Err(_errNotFound); // на L5: 404 и на DELETE
    _items.removeAt(index);
    return const Ok(null); // «удалил, отдать нечего» — как 204 с пустым телом
  }
}
