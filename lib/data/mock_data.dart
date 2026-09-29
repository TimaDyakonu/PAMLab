// data/mock_data.dart — seed-данные для mock-репозиториев.
// Этот файл видит только data/mock_*_repository.dart и корень композиции
// main.dart: экраны, widget-ы и модели о нём не знают. На L5 данные придут
// из backend-а, и файл исчезнет вместе с mock-ом.
import 'catalog.dart';
import 'item.dart';
import 'reservation.dart';
import 'user.dart';

const mockUsers = [
  User('u1', 'Admin', 'admin@secondhand.md'),
  User('u2', 'Ион Русу', 'ion.rusu@gmail.com'),
  User('u3', 'Мария Попеску', 'maria.popescu@mail.md'),
  User('u4', 'Андрей Лунгу', 'andrei.lungu@gmail.com'),
  User('u5', 'Елена Кожокару', 'elena.cojocaru@mail.md'),
];

/// Пользователь, «вошедший» в приложение (вход на L4 — локальная валидация).
final mockCurrentUser = mockUsers[0];

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
    category: catalogCategories[1],
    owner: mockUsers[1],
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
    category: catalogCategories[0],
    owner: mockUsers[2],
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
    category: catalogCategories[2],
    owner: mockUsers[4],
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
    category: catalogCategories[4],
    owner: mockUsers[3],
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
    category: catalogCategories[3],
    owner: mockUsers[1],
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
    category: catalogCategories[0],
    owner: mockUsers[4],
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
    category: catalogCategories[5],
    owner: mockUsers[2],
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
    category: catalogCategories[3],
    owner: mockUsers[3],
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
    category: catalogCategories[2],
    owner: mockUsers[2],
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
    category: catalogCategories[4],
    owner: mockUsers[1],
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
    category: catalogCategories[0],
    owner: mockUsers[0],
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
    category: catalogCategories[1],
    owner: mockUsers[0],
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
    category: catalogCategories[3],
    owner: mockUsers[0],
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
    category: catalogCategories[4],
    owner: mockUsers[0],
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
    category: catalogCategories[2],
    owner: mockUsers[0],
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
    category: catalogCategories[5],
    owner: mockUsers[0],
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


// --- временные помощники: исчезнут, когда все экраны перейдут на модели ---
User userById(String id) => mockUsers.firstWhere((u) => u.id == id);
Item itemById(String id) => mockItems.firstWhere((i) => i.id == id);

List<Item> get feedItems =>
    mockItems.where((i) => i.owner.id != mockCurrentUser.id).toList();

List<Item> get myItems =>
    mockItems.where((i) => i.owner.id == mockCurrentUser.id).toList();
