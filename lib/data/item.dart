// data/item.dart — главная сущность темы: вещь в объявлении.
import 'catalog.dart';
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

  /// Граница JSON (L5): так вещь приходит от сервера вместе с продавцом.
  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: '${json['id']}',
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        price: (json['price'] as num).toDouble(), // 120 приходит как int!
        size: json['size'] as String,
        condition: json['condition'] as String,
        category: catalogCategories.firstWhere(
          (c) => c.id == json['categoryId'],
          orElse: () => catalogCategories.first,
        ),
        imageUrl: json['imageUrl'] as String? ?? '',
        owner: User.fromJson(json['owner'] as Map<String, dynamic>),
        status: ItemStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  /// Тело POST /items и PUT /items/{id}: без id, идентичность даёт сервер.
  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'price': price,
        'size': size,
        'condition': condition,
        'categoryId': category.id,
        'imageUrl': imageUrl,
      };

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
