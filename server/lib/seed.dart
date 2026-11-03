// Demo data, inserted once when the database is empty (first start).
//
// Five users: the "Admin" account owns six items and six reservations, the
// other four users sell the rest of the feed. More than 20 items are in the
// feed on purpose, so that pagination is visible at the default page size.
// The passwords are laboratory data (never do this outside a lab).

import 'dart:io';

import 'auth.dart';
import 'db.dart';
import 'files.dart';

const _users = [
  ('admin@secondhand.md', 'Admin', 'admin123'),
  ('ion.rusu@gmail.com', 'Ион Русу', 'parola123'),
  ('maria.popescu@mail.md', 'Мария Попеску', 'parola123'),
  ('andrei.lungu@gmail.com', 'Андрей Лунгу', 'parola123'),
  ('elena.cojocaru@mail.md', 'Елена Кожокару', 'parola123'),
];

// owner (1-based user), title, description, price, size, condition,
// categoryId, status, createdAt
const _items = [
  (2, "Джинсы Levi's 501 Original, прямой крой", "Классические 501, плотный деним. Носила один сезон, без потёртостей и пятен. Длина подойдёт на рост 175–180 см.", 350.0, "W32 L32", "Отличное", "c2", "available", "2026-09-16T10:00:00.000Z"),
  (3, "Пуховик The North Face Nuptse 700, чёрный", "Тёплый пуховик на холодную зиму. Молнии и кнопки работают, наполнитель не сбился. Есть мелкая затяжка на рукаве.", 1850.0, "M", "Хорошее", "c1", "available", "2026-09-15T10:00:00.000Z"),
  (5, "Платье миди Zara в цветочный принт", "Лёгкое летнее платье из вискозы, на пуговицах. Надевала два раза, стирка только ручная.", 280.0, "S", "Отличное", "c3", "available", "2026-09-14T10:00:00.000Z"),
  (4, "Кроссовки Nike Air Force 1 Low, белые", "Оригинал, куплены в официальном магазине. Подошва чистая, на носке небольшие заломы. Коробка сохранилась.", 950.0, "42", "Хорошее", "c5", "reserved", "2026-09-12T10:00:00.000Z"),
  (2, "Худи Carhartt WIP Hooded Chase, серый меланж", "Плотный хлопок с начёсом, вышитый логотип. Не садится после стирки, манжеты не растянуты.", 620.0, "L", "Отличное", "c4", "available", "2026-09-11T10:00:00.000Z"),
  (5, "Шерстяное пальто Mango оверсайз, кэмел", "Пальто из смесовой шерсти (60 %), на подкладке. Подойдёт на размеры S–M за счёт свободного кроя.", 1200.0, "S", "Новое с биркой", "c1", "available", "2026-09-10T10:00:00.000Z"),
  (3, "Кожаная сумка через плечо, ручная работа", "Натуральная кожа, один основной отдел и карман на молнии. Ремень регулируется по длине.", 450.0, "Без размера", "Хорошее", "c6", "sold", "2026-09-09T10:00:00.000Z"),
  (4, "Свитер H&M крупной вязки, молочный", "Объёмный свитер с горлом, акрил с шерстью. Катышков нет, вещь очень тёплая.", 190.0, "M", "Хорошее", "c4", "available", "2026-09-08T10:00:00.000Z"),
  (3, "Юбка плиссе Reserved, тёмно-зелёная", "Юбка миди на резинке, складки держат форму. Подходит и под кеды, и под ботинки.", 160.0, "XS", "Удовлетворительное", "c3", "sold", "2026-09-05T10:00:00.000Z"),
  (2, "Ботинки Dr. Martens 1460, вишнёвые", "Гладкая кожа, 8 люверсов. Разношены, но без трещин на сгибах; подошва AirWair в отличном состоянии.", 1400.0, "38", "Хорошее", "c5", "reserved", "2026-09-03T10:00:00.000Z"),
  (1, "Джинсовая куртка Pull&Bear, светлая варёнка", "Укороченная куртка, металлические пуговицы. Стала мала в плечах, поэтому продаю.", 300.0, "S", "Отличное", "c1", "available", "2026-09-17T10:00:00.000Z"),
  (1, "Брюки палаццо Massimo Dutti, лён", "Широкие льняные брюки с высокой посадкой, бежевые. Идеальны на лето.", 420.0, "M", "Новое с биркой", "c2", "available", "2026-09-13T10:00:00.000Z"),
  (1, "Кардиган Bershka с жемчужными пуговицами", "Мягкий трикотаж, укороченная длина. Одна пуговица перешита, это почти незаметно.", 150.0, "S", "Хорошее", "c4", "reserved", "2026-09-07T10:00:00.000Z"),
  (1, "Кеды Converse Chuck Taylor All Star High", "Высокие чёрные кеды, носила аккуратно. Стельки заменены на новые.", 380.0, "38", "Хорошее", "c5", "sold", "2026-08-30T10:00:00.000Z"),
  (1, "Сарафан в клетку Zara, вельвет", "Вельветовый сарафан на широких бретелях, с карманами спереди.", 240.0, "XS", "Отличное", "c3", "available", "2026-08-28T10:00:00.000Z"),
  (1, "Шарф Uniqlo из кашемира, графитовый", "100 % кашемир, 180 × 30 см. Не колется, хранился в чехле.", 320.0, "Без размера", "Отличное", "c6", "sold", "2026-08-20T10:00:00.000Z"),
  (5, "Блуза Mango из шёлка, пудровая", "Лёгкая блуза с воротником-бантом, шёлк, без дефектов. Носила пару раз.", 260.0, "S", "Отличное", "c3", "available", "2026-09-18T10:00:00.000Z"),
  (2, "Рубашка Tommy Hilfiger, оксфорд", "Классическая рубашка из плотного хлопка, воротник не потёрт, цвет небесно-голубой.", 310.0, "L", "Хорошее", "c4", "available", "2026-09-18T10:00:00.000Z"),
  (4, "Кроссовки Adidas Samba, чёрные", "Оригинальные Samba, подошва почти без износа, замшевые вставки чистые.", 780.0, "42", "Хорошее", "c5", "available", "2026-09-19T10:00:00.000Z"),
  (3, "Шорты Levi's 501, светлый деним", "Короткие шорты из плотного денима, потёртости сделаны фабрично, без пятен.", 190.0, "S", "Отличное", "c2", "available", "2026-09-19T10:00:00.000Z"),
  (5, "Платье-комбинация Zara, атлас, чёрное", "Платье на тонких бретелях, атлас, новое, с биркой. Не подошёл размер.", 350.0, "M", "Новое с биркой", "c3", "available", "2026-09-19T10:00:00.000Z"),
  (2, "Ремень кожаный Pierre Cardin, коричневый", "Натуральная кожа, металлическая пряжка, на коже есть следы носки.", 120.0, "Без размера", "Хорошее", "c6", "available", "2026-09-20T10:00:00.000Z"),
  (4, "Свитшот Nike Club, серый", "Плотный хлопок с начёсом, вышитый логотип, манжеты не растянуты.", 280.0, "M", "Отличное", "c4", "available", "2026-09-20T10:00:00.000Z"),
  (3, "Куртка-бомбер Alpha Industries, оливковая", "Классический бомбер с оранжевой подкладкой, молнии работают, без дырок.", 1100.0, "L", "Хорошее", "c1", "available", "2026-09-20T10:00:00.000Z"),
  (5, "Сапоги Zara замшевые на каблуке", "Замша без залысин, каблук 6 см, носили один сезон, подошву не стирали.", 520.0, "38", "Отличное", "c5", "available", "2026-09-20T10:00:00.000Z"),
  (2, "Рюкзак The North Face Borealis, чёрный", "Вместительный рюкзак на 28 литров, молнии целые, лямки не потёртые.", 650.0, "Без размера", "Хорошее", "c6", "available", "2026-09-21T10:00:00.000Z"),
  (4, "Джинсы Wrangler Texas, прямые", "Прямые джинсы из плотного денима, шов по низу не распущен, цвет тёмно-синий.", 270.0, "W32 L32", "Хорошее", "c2", "available", "2026-09-21T10:00:00.000Z"),
  (3, "Кардиган H&M мохер, бежевый", "Мягкий кардиган свободного кроя, катышков нет, пуговицы на месте.", 170.0, "L", "Хорошее", "c4", "available", "2026-09-21T10:00:00.000Z"),
];

// item (1-based, in the order of _items), status, createdAt; buyer is Admin
const _reservations = [
  (4, 'pending', '2026-09-17T10:00:00.000Z'),
  (10, 'confirmed', '2026-09-15T10:00:00.000Z'),
  (9, 'completed', '2026-09-06T10:00:00.000Z'),
  (2, 'cancelled', '2026-09-04T10:00:00.000Z'),
  (8, 'cancelled', '2026-09-02T10:00:00.000Z'),
  (7, 'completed', '2026-08-25T10:00:00.000Z'),
];

/// Fills an empty database with the demo users, items and reservations.
void seedIfEmpty() {
  final count = db.select('SELECT COUNT(*) AS n FROM users').first['n'] as int;
  if (count > 0) return;

  inTransaction(() {
    _seedUsers();
    _seedItems();
    _seedPhotos();
    _seedReservations();
  });
}

/// Item photos of the demo data: seed/photos/01.jpg ... 28.jpg, numbered in the
/// order of [_items]. Each one is stored like a normal upload (a row in files
/// plus a copy in uploads/), and the item points to it with /files/{id}.
/// Needs initFileStorage() to have run; a missing photo is simply skipped.
void _seedPhotos() {
  for (var i = 1; i <= _items.length; i++) {
    final name = '${i.toString().padLeft(2, '0')}.jpg';
    final source = File('seed/photos/$name');
    if (!source.existsSync()) continue;

    final owner = _items[i - 1].$1;
    final stored = File('${uploadsDir.path}/seed_$name');
    source.copySync(stored.path);
    db.execute(
      'INSERT INTO files (user_id, name, mime_type, size, path, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      [owner, name, 'image/jpeg', stored.lengthSync(), stored.path, nowIso()],
    );
    db.execute(
      'UPDATE items SET image_url = ? WHERE id = ?',
      ['/files/${db.lastInsertRowId}', i],
    );
  }
}

void _seedUsers() {
  for (final (email, name, password) in _users) {
    db.execute(
      'INSERT INTO users (email, password_hash, name, created_at) '
      'VALUES (?, ?, ?, ?)',
      [email, hashPassword(password), name, nowIso()],
    );
  }
}

void _seedItems() {
  for (final (owner, title, text, price, size, condition, category, status, at)
      in _items) {
    db.execute(
      'INSERT INTO items (user_id, title, description, price, size, '
      'condition, category_id, status, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [owner, title, text, price, size, condition, category, status, at],
    );
  }
}

void _seedReservations() {
  for (final (item, status, at) in _reservations) {
    db.execute(
      'INSERT INTO reservations (item_id, buyer_id, status, created_at) '
      'VALUES (?, 1, ?, ?)',
      [item, status, at],
    );
  }
}
