// data/catalog.dart — закрытые справочники: категории, размеры, состояния.
// Это классификаторы приложения (как enum), а не данные пользователей:
// они меняются только релизом, поэтому лежат в коде, а не в repository.
import 'package:flutter/material.dart';
import 'category.dart';

const catalogCategories = [
  Category('c1', 'Верхняя одежда', Icons.dry_cleaning),
  Category('c2', 'Джинсы и брюки', Icons.style),
  Category('c3', 'Платья и юбки', Icons.woman),
  Category('c4', 'Свитеры и худи', Icons.checkroom),
  Category('c5', 'Обувь', Icons.snowshoeing),
  Category('c6', 'Аксессуары', Icons.shopping_bag),
];

const catalogSizes = ['XS', 'S', 'M', 'L', 'XL', '38', '42', 'W32 L32'];

const catalogConditions = [
  'Новое с биркой',
  'Отличное',
  'Хорошее',
  'Удовлетворительное',
];
