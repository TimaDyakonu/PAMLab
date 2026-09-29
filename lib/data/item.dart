// data/item.dart — главная сущность темы: вещь в объявлении.
import 'category.dart';
import 'user.dart';

/// Статус вещи: жизненный цикл «доступна → забронирована → продана».
enum ItemStatus {
  available('Доступна'),
  reserved('Забронирована'),
  sold('Продана');

  final String label;
  const ItemStatus(this.label);
}

class Item {
  final String id;
  final String title;
  final String description;
  final double price;
  final String size;
  final String condition;
  final Category category;
  final String imageUrl; // пусто — вместо фото иконка категории
  final User owner; // продавец: на L5 backend вернёт его вместе с вещью
  final ItemStatus status;
  final DateTime createdAt;

  const Item({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.size,
    required this.condition,
    required this.category,
    this.imageUrl = '',
    required this.owner,
    required this.status,
    required this.createdAt,
  });

  String get priceLabel => '${price.toStringAsFixed(0)} MDL';

  /// Та же вещь, другая идентичность или статус: id выдаёт хранилище,
  /// статус меняют бронь и продажа.
  Item copyWith({String? id, ItemStatus? status}) => Item(
        id: id ?? this.id,
        title: title,
        description: description,
        price: price,
        size: size,
        condition: condition,
        category: category,
        imageUrl: imageUrl,
        owner: owner,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}
