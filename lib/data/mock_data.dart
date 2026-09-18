// data/mock_data.dart — mock-модель: поля берутся из модели данных темы
// (Item, Reservation, User, Category). На L2 данные зашиты в код;
// на L5 их заменит backend.
import 'package:flutter/material.dart';

/// Статус вещи: жизненный цикл «доступна → забронирована → продана».
enum ItemStatus {
  available('Доступна'),
  reserved('Забронирована'),
  sold('Продана');

  final String label;
  const ItemStatus(this.label);
}

/// Статус брони с точки зрения покупателя.
enum ReservationStatus {
  pending('Ожидает ответа'),
  confirmed('Подтверждена'),
  completed('Завершена'),
  cancelled('Отменена');

  final String label;
  const ReservationStatus(this.label);
}

class User {
  final String id;
  final String name;
  final String email;
  final String avatarUrl; // на L2 пусто — вместо фото аватар с инициалами

  const User(this.id, this.name, this.email, [this.avatarUrl = '']);
}

class Category {
  final String id;
  final String name;
  final IconData icon; // только для UI: иконка-заглушка вместо фотографии

  const Category(this.id, this.name, this.icon);
}

class Item {
  final String id;
  final String title;
  final String description;
  final double price;
  final String size;
  final String condition;
  final Category category;
  final String imageUrl; // на L2 пусто — вместо фото иконка категории
  final String ownerId;
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
    required this.ownerId,
    required this.status,
    required this.createdAt,
  });

  String get priceLabel => '${price.toStringAsFixed(0)} MDL';
}

class Reservation {
  final String id;
  final String itemId;
  final String buyerId;
  final ReservationStatus status;
  final DateTime createdAt;

  const Reservation(
      this.id, this.itemId, this.buyerId, this.status, this.createdAt);
}

/// Дата в формате 18.09.2026.
String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

// ---------------------------------------------------------------------------
// Зашитые в код данные, реалистичные для домена
// ---------------------------------------------------------------------------

const mockCategories = [
  Category('c1', 'Верхняя одежда', Icons.dry_cleaning),
  Category('c2', 'Джинсы и брюки', Icons.style),
  Category('c3', 'Платья и юбки', Icons.woman),
  Category('c4', 'Свитеры и худи', Icons.checkroom),
  Category('c5', 'Обувь', Icons.snowshoeing),
  Category('c6', 'Аксессуары', Icons.shopping_bag),
];

const mockSizes = ['XS', 'S', 'M', 'L', 'XL', '38', '42', 'W32 L32'];

const mockConditions = [
  'Новое с биркой',
  'Отличное',
  'Хорошее',
  'Удовлетворительное',
];

const mockUsers = [
  User('u1', 'Admin', 'admin@secondhand.md'),
  User('u2', 'Ион Русу', 'ion.rusu@gmail.com'),
  User('u3', 'Мария Попеску', 'maria.popescu@mail.md'),
  User('u4', 'Андрей Лунгу', 'andrei.lungu@gmail.com'),
  User('u5', 'Елена Кожокару', 'elena.cojocaru@mail.md'),
];

/// Пользователь, «вошедший» в приложение.
const currentUser = User('u1', 'Admin', 'admin@secondhand.md');

final mockItems = [
  // --- вещи других пользователей: лента объявлений ---
  Item(
    id: 'i1',
    title: "Джинсы Levi's 501 Original, прямой крой",
    description: 'Классические 501, плотный деним. Носила один сезон, '
        'без потёртостей и пятен. Длина подойдёт на рост 175–180 см.',
    price: 350,
    size: 'W32 L32',
    condition: 'Отличное',
    category: mockCategories[1],
    ownerId: 'u2',
    status: ItemStatus.available,
    createdAt: DateTime(2026, 9, 16),
  ),
  Item(
    id: 'i2',
    title: 'Пуховик The North Face Nuptse 700, чёрный',
    description: 'Тёплый пуховик на холодную зиму. Молнии и кнопки '
        'работают, наполнитель не сбился. Есть мелкая затяжка на рукаве.',
    price: 1850,
    size: 'M',
    condition: 'Хорошее',
    category: mockCategories[0],
    ownerId: 'u3',
    status: ItemStatus.available,
    createdAt: DateTime(2026, 9, 15),
  ),
  Item(
    id: 'i3',
    title: 'Платье миди Zara в цветочный принт',
    description: 'Лёгкое летнее платье из вискозы, на пуговицах. '
        'Надевала два раза, стирка только ручная.',
    price: 280,
    size: 'S',
    condition: 'Отличное',
    category: mockCategories[2],
    ownerId: 'u5',
    status: ItemStatus.available,
    createdAt: DateTime(2026, 9, 14),
  ),
  Item(
    id: 'i4',
    title: 'Кроссовки Nike Air Force 1 Low, белые',
    description: 'Оригинал, куплены в официальном магазине. Подошва '
        'чистая, на носке небольшие заломы. Коробка сохранилась.',
    price: 950,
    size: '42',
    condition: 'Хорошее',
    category: mockCategories[4],
    ownerId: 'u4',
    status: ItemStatus.reserved,
    createdAt: DateTime(2026, 9, 12),
  ),
  Item(
    id: 'i5',
    title: 'Худи Carhartt WIP Hooded Chase, серый меланж',
    description: 'Плотный хлопок с начёсом, вышитый логотип. '
        'Не садится после стирки, манжеты не растянуты.',
    price: 620,
    size: 'L',
    condition: 'Отличное',
    category: mockCategories[3],
    ownerId: 'u2',
    status: ItemStatus.available,
    createdAt: DateTime(2026, 9, 11),
  ),
  Item(
    id: 'i6',
    title: 'Шерстяное пальто Mango оверсайз, кэмел',
    description: 'Пальто из смесовой шерсти (60 %), на подкладке. '
        'Подойдёт на размеры S–M за счёт свободного кроя.',
    price: 1200,
    size: 'S',
    condition: 'Новое с биркой',
    category: mockCategories[0],
    ownerId: 'u5',
    status: ItemStatus.available,
    createdAt: DateTime(2026, 9, 10),
  ),
  Item(
    id: 'i7',
    title: 'Кожаная сумка через плечо, ручная работа',
    description: 'Натуральная кожа, один основной отдел и карман на '
        'молнии. Ремень регулируется по длине.',
    price: 450,
    size: 'Без размера',
    condition: 'Хорошее',
    category: mockCategories[5],
    ownerId: 'u3',
    status: ItemStatus.sold,
    createdAt: DateTime(2026, 9, 9),
  ),
  Item(
    id: 'i8',
    title: 'Свитер H&M крупной вязки, молочный',
    description: 'Объёмный свитер с горлом, акрил с шерстью. '
        'Катышков нет, вещь очень тёплая.',
    price: 190,
    size: 'M',
    condition: 'Хорошее',
    category: mockCategories[3],
    ownerId: 'u4',
    status: ItemStatus.available,
    createdAt: DateTime(2026, 9, 8),
  ),
  Item(
    id: 'i9',
    title: 'Юбка плиссе Reserved, тёмно-зелёная',
    description: 'Юбка миди на резинке, складки держат форму. '
        'Подходит и под кеды, и под ботинки.',
    price: 160,
    size: 'XS',
    condition: 'Удовлетворительное',
    category: mockCategories[2],
    ownerId: 'u3',
    status: ItemStatus.sold,
    createdAt: DateTime(2026, 9, 5),
  ),
  Item(
    id: 'i10',
    title: 'Ботинки Dr. Martens 1460, вишнёвые',
    description: 'Гладкая кожа, 8 люверсов. Разношены, но без трещин '
        'на сгибах; подошва AirWair в отличном состоянии.',
    price: 1400,
    size: '38',
    condition: 'Хорошее',
    category: mockCategories[4],
    ownerId: 'u2',
    status: ItemStatus.reserved,
    createdAt: DateTime(2026, 9, 3),
  ),

  // --- вещи текущего пользователя (u1): «Мои объявления» ---
  Item(
    id: 'i11',
    title: 'Джинсовая куртка Pull&Bear, светлая варёнка',
    description: 'Укороченная куртка, металлические пуговицы. '
        'Стала мала в плечах, поэтому продаю.',
    price: 300,
    size: 'S',
    condition: 'Отличное',
    category: mockCategories[0],
    ownerId: 'u1',
    status: ItemStatus.available,
    createdAt: DateTime(2026, 9, 17),
  ),
  Item(
    id: 'i12',
    title: 'Брюки палаццо Massimo Dutti, лён',
    description: 'Широкие льняные брюки с высокой посадкой, '
        'бежевые. Идеальны на лето.',
    price: 420,
    size: 'M',
    condition: 'Новое с биркой',
    category: mockCategories[1],
    ownerId: 'u1',
    status: ItemStatus.available,
    createdAt: DateTime(2026, 9, 13),
  ),
  Item(
    id: 'i13',
    title: 'Кардиган Bershka с жемчужными пуговицами',
    description: 'Мягкий трикотаж, укороченная длина. '
        'Одна пуговица перешита, это почти незаметно.',
    price: 150,
    size: 'S',
    condition: 'Хорошее',
    category: mockCategories[3],
    ownerId: 'u1',
    status: ItemStatus.reserved,
    createdAt: DateTime(2026, 9, 7),
  ),
  Item(
    id: 'i14',
    title: 'Кеды Converse Chuck Taylor All Star High',
    description: 'Высокие чёрные кеды, носила аккуратно. '
        'Стельки заменены на новые.',
    price: 380,
    size: '38',
    condition: 'Хорошее',
    category: mockCategories[4],
    ownerId: 'u1',
    status: ItemStatus.sold,
    createdAt: DateTime(2026, 8, 30),
  ),
  Item(
    id: 'i15',
    title: 'Сарафан в клетку Zara, вельвет',
    description: 'Вельветовый сарафан на широких бретелях, '
        'с карманами спереди.',
    price: 240,
    size: 'XS',
    condition: 'Отличное',
    category: mockCategories[2],
    ownerId: 'u1',
    status: ItemStatus.available,
    createdAt: DateTime(2026, 8, 28),
  ),
  Item(
    id: 'i16',
    title: 'Шарф Uniqlo из кашемира, графитовый',
    description: '100 % кашемир, 180 × 30 см. Не колется, '
        'хранился в чехле.',
    price: 320,
    size: 'Без размера',
    condition: 'Отличное',
    category: mockCategories[5],
    ownerId: 'u1',
    status: ItemStatus.sold,
    createdAt: DateTime(2026, 8, 20),
  ),
];

/// Брони текущего пользователя как покупателя: «Мои покупки».
final mockReservations = [
  Reservation('r1', 'i4', 'u1', ReservationStatus.pending,
      DateTime(2026, 9, 17)),
  Reservation('r2', 'i10', 'u1', ReservationStatus.confirmed,
      DateTime(2026, 9, 15)),
  Reservation('r3', 'i9', 'u1', ReservationStatus.completed,
      DateTime(2026, 9, 6)),
  Reservation('r4', 'i2', 'u1', ReservationStatus.cancelled,
      DateTime(2026, 9, 4)),
  Reservation('r5', 'i8', 'u1', ReservationStatus.cancelled,
      DateTime(2026, 9, 2)),
  Reservation('r6', 'i7', 'u1', ReservationStatus.completed,
      DateTime(2026, 8, 25)),
];

// Поиск по id — вместо запросов к backend-у на L5.
User userById(String id) => mockUsers.firstWhere((u) => u.id == id);
Item itemById(String id) => mockItems.firstWhere((i) => i.id == id);

/// Вещи других пользователей — содержимое ленты.
List<Item> get feedItems =>
    mockItems.where((i) => i.ownerId != currentUser.id).toList();

/// Вещи, которые продаёт текущий пользователь.
List<Item> get myItems =>
    mockItems.where((i) => i.ownerId == currentUser.id).toList();
