# Отчёт по лабораторной работе № 2 — черновик

> Черновик текста для `PAM_L2_DiaconuTimotei.pdf`. Перенесите в Word по шаблону L1,
> вставьте скриншоты на места `[СКРИНШОТ …]` и экспортируйте в PDF.
> Проверьте фамилию преподавателя на титульном листе.

---

## Титульный лист

TEHNICAL UNIVERSITY OF MOLDOVA
Технический университет Молдовы
Факультет вычислительной техники, информатики и микроэлектроники (FCIM)
Департамент программной инженерии и автоматики

**ОТЧЁТ**
по лабораторной работе № 2
«Статический UI приложения: экраны темы в Material 3»
Дисциплина: Программирование мобильных приложений (PAM)

Выполнил: студент группы TI-235, Diaconu Timotei
Проверил: унив. лектор Leah Arcadie

Кишинёв, 2026

**Тема проекта** (собственная, утверждена на защите L1): платформа для обмена и продажи
одежды между пользователями (P2P-маркетплейс секонд-хенда).
Домен: электронная коммерция / P2P-маркетплейс. Сложность: средняя.

Репозиторий: https://github.com/TimaDyakonu/PAMLab

---

## 1. Структура проекта

Проект создан командой `flutter create second_hand_market` (имя темы строчными буквами
через подчёркивание) и организован по схеме из методички, чтобы на L3–L6 он только рос,
а не реорганизовывался.

```
lib/
├── main.dart                     # MaterialApp + тема + стартовый экран
├── data/
│   └── mock_data.dart            # модели и зашитые в код данные
├── screens/
│   ├── login_screen.dart         # Вход / регистрация
│   ├── home_screen.dart          # временная обёртка с NavigationBar
│   ├── feed_screen.dart          # Лента объявлений
│   ├── item_details_screen.dart  # Карточка вещи
│   ├── new_item_screen.dart      # Публикация объявления
│   ├── my_items_screen.dart      # Мои объявления
│   ├── my_purchases_screen.dart  # Бронирование / мои покупки
│   └── profile_screen.dart       # Профиль пользователя
└── widgets/
    ├── item_card.dart            # плитка вещи для сетки ленты
    ├── item_tile.dart            # строка вещи для списков
    ├── item_photo.dart           # заглушка фотографии вещи
    ├── status_badge.dart         # бейдж статуса вещи или брони
    └── user_avatar.dart          # аватар с инициалами
```

- **`main.dart`** — точка входа: создаёт `MaterialApp`, задаёт светлую и тёмную тему и
  открывает экран входа.
- **`data/`** — классы модели данных темы (`Item`, `Reservation`, `User`, `Category`,
  перечисления статусов) и mock-списки, которые используются сразу на нескольких экранах.
- **`screens/`** — по одному файлу на каждый обязательный экран; все экраны —
  `StatelessWidget`.
- **`widgets/`** — переиспользуемые компоненты, параметризованные через конструктор.

---

## 2. Визуальная тема

```dart
// Семя палитры — приглушённый лесной зелёный: цвет осознанного
// потребления и вторичного использования вещей (эко-тематика секонд-хенда).
const _seedColor = Color(0xFF4A7C59);

MaterialApp(
  title: 'Second Hand Market',
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  darkTheme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  themeMode: ThemeMode.system,
  home: const LoginScreen(),
);
```

**Обоснование цвета.** Секонд-хенд — это прежде всего осознанное потребление и повторное
использование вещей, поэтому выбран приглушённый зелёный, ассоциирующийся с экологией; он
спокойный и не спорит с цветами самих вещей на фотографиях.

В экранах цвета не зашиты в код: везде используются роли темы
(`Theme.of(context).colorScheme.primary`, `primaryContainer`, `surfaceContainerHighest`,
`onSurfaceVariant` и т.д.). Поэтому при смене `seedColor` и hot reload перекрашивается весь
интерфейс, а тёмная тема (`darkTheme` с тем же семенем) работает без единой правки в экранах.

---

## 3. Экраны

Порядок и названия — по списку экранов из спецификации темы. Данные на всех экранах
зашиты в код (`lib/data/mock_data.dart`), кнопки на L2 не имеют эффекта.

**Выбор по изображениям.** Фотографий вещей на L2 нет: вместо фото используется
widget `ItemPhoto` — иконка категории вещи на приглушённом фоне `surfaceContainerHighest`.
Вместо фото пользователя — аватар с инициалами (`UserAvatar`). На L5 их заменят
изображения, загруженные на сервер.

### 3.1 Вход / регистрация

[СКРИНШОТ: экран входа]

Экран показывает логотип, поле e-mail, поле пароля (`obscureText: true`), главную кнопку
`FilledButton` «Войти» и `TextButton` «Нет аккаунта? Зарегистрируйтесь». Экран строго
статический — без `Form`, без `validator`, без проверки полей; кнопка «Войти» только
открывает стартовый экран, чтобы не блокировать демонстрацию. Основные widget-ы:
`Scaffold`, `SingleChildScrollView`, `Column`, `TextField`, `FilledButton`, `TextButton`.

### 3.2 Лента объявлений (поиск + фильтр по категории/размеру)

[СКРИНШОТ: лента]

Показывает строку поиска (`SearchBar`), два горизонтальных ряда фильтров — по категории и
по размеру (`FilterChip` в горизонтальном `ListView.separated`) — и сетку из 10 вещей
других пользователей (`GridView.builder` с `ItemCard`). Сетка обёрнута в `Expanded`, чтобы
получить конечную высоту внутри `Column`. Фильтры и поиск пока только визуальные —
работать они начнут на L4. Кнопка `FloatingActionButton` «Продать» ведёт на экран
публикации.

### 3.3 Карточка вещи (фото, описание, цена, размер, состояние, продавец)

[СКРИНШОТ: карточка вещи]

Показывает один mock-объект: заглушку фото (`ItemPhoto` в `AspectRatio`), цену и статус
(`StatusBadge`), название, `Card` с `ListTile`-строками «Размер», «Состояние»,
«Категория», «Опубликовано», описание и `Card` продавца с `UserAvatar`. Внизу закреплены
кнопки «Написать» (`OutlinedButton`) и «Забронировать» (`FilledButton`).

### 3.4 Публикация объявления

[СКРИНШОТ: публикация объявления]

Макет формы добавления вещи: ряд мест под фотографии, `TextField`-ы «Название»,
«Описание», «Цена» (с суффиксом MDL), `DropdownMenu` для категории, размера и состояния,
`SwitchListTile` «Готов(а) к обмену» и кнопка «Опубликовать». Без валидации и без
сохранения — это материал L3–L5.

### 3.5 Мои объявления

[СКРИНШОТ: мои объявления]

Список из 6 вещей, которые продаёт текущий пользователь, в `ListView.separated`. Каждая
строка — `ItemTile`: заглушка фото, название, размер, состояние, дата публикации, статус
(«Доступна», «Забронирована», «Продана») и цена.

### 3.6 Бронирование / мои покупки

[СКРИНШОТ: мои покупки]

Список из 6 броней текущего пользователя в `ListView.separated`. Используется тот же
`ItemTile`, но вместо статуса вещи в него передаётся статус брони
(`StatusBadge.reservation`: «Ожидает ответа», «Подтверждена», «Завершена», «Отменена»),
а в подписи — имя продавца и дата брони.

### 3.7 Профиль пользователя

[СКРИНШОТ: профиль]

Показывает аватар с инициалами, имя и e-mail, три плитки статистики («В продаже»,
«Продано», «Покупок» — считаются по mock-данным) и `Card` с пунктами «Личные данные»,
«Избранное», «Город», «Уведомления», а также кнопку «Выйти» (`OutlinedButton`).

### Навигация для демонстрации

Выбран вариант 2 из Задания 6: временная обёртка `HomeScreen` с `NavigationBar` на 4
вкладки («Лента», «Мои вещи», «Покупки», «Профиль»). Это единственный `StatefulWidget`
в приложении: он хранит только индекс выбранной вкладки. Второстепенные экраны
открываются через `Navigator.push`: карточка вещи — нажатием на вещь в ленте, публикация —
кнопкой «Продать». На L3 это заменит настоящая навигация.

---

## 4. Переиспользуемые widget-ы

Все widget-ы — `StatelessWidget`, параметризованные через конструктор; изменение вида в
одном файле меняет его на всех экранах, где он используется.

| Widget | Параметры | Где используется |
|---|---|---|
| `ItemCard` | `item`, `onTap` | Лента (каждая плитка сетки) |
| `ItemTile` | `item`, `badge`, `footer` | Мои объявления, Мои покупки |
| `ItemPhoto` | `category`, `iconSize` | Лента, Карточка вещи, Мои объявления, Мои покупки |
| `StatusBadge` | `.item(status)` / `.reservation(status)` | Лента, Карточка вещи, Мои объявления, Мои покупки |
| `UserAvatar` | `user`, `radius` | Карточка вещи (продавец), Профиль |

### ItemCard — `lib/widgets/item_card.dart`

```dart
// widgets/item_card.dart — плитка вещи для сетки ленты.
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import 'item_photo.dart';
import 'status_badge.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;

  const ItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias, // фото обрезается по скруглённым углам
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // фото занимает всё, что осталось после текста
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ItemPhoto(category: item.category),
                  if (item.status != ItemStatus.available)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: StatusBadge.item(item.status),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.priceLabel,
                    style: text.titleMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.size} · ${item.condition}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### ItemTile — `lib/widgets/item_tile.dart`

```dart
// widgets/item_tile.dart — строка вещи для списков
// («Мои объявления», «Мои покупки»).
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import 'item_photo.dart';
import 'status_badge.dart';

class ItemTile extends StatelessWidget {
  final Item item;

  /// Бейдж справа внизу. По умолчанию — статус самой вещи;
  /// на экране покупок сюда передаётся статус брони.
  final Widget? badge;

  /// Дополнительная строка под названием (продавец, дата брони…).
  final String? footer;

  const ItemTile({
    super.key,
    required this.item,
    this.badge,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 72,
                child: ItemPhoto(category: item.category, iconSize: 32),
              ),
            ),
            const SizedBox(width: 12),
            // Expanded: реальный предел ширины — длинное название
            // переносится, а не вызывает переполнение
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    footer ?? '${item.size} · ${item.condition}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      badge ?? StatusBadge.item(item.status),
                      Text(
                        item.priceLabel,
                        style: text.titleMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### ItemPhoto — `lib/widgets/item_photo.dart`

```dart
// widgets/item_photo.dart — заглушка фотографии вещи.
// На L2 фото нет (imageUrl пуст): показываем иконку категории на
// приглушённом фоне. Заполняет ту коробку, которую ему дал родитель.
import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class ItemPhoto extends StatelessWidget {
  final Category category;
  final double iconSize;

  const ItemPhoto({super.key, required this.category, this.iconSize = 48});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        category.icon,
        size: iconSize,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
```

### StatusBadge — `lib/widgets/status_badge.dart`

```dart
// widgets/status_badge.dart — бейдж статуса вещи или брони.
// Цвета берутся из ролей темы, а не зашиваются в код.
import 'package:flutter/material.dart';
import '../data/mock_data.dart';

enum _Tone { primary, secondary, tertiary, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final _Tone _tone;

  StatusBadge.item(ItemStatus status, {super.key})
      : label = status.label,
        _tone = switch (status) {
          ItemStatus.available => _Tone.primary,
          ItemStatus.reserved => _Tone.tertiary,
          ItemStatus.sold => _Tone.neutral,
        };

  StatusBadge.reservation(ReservationStatus status, {super.key})
      : label = status.label,
        _tone = switch (status) {
          ReservationStatus.pending => _Tone.tertiary,
          ReservationStatus.confirmed => _Tone.primary,
          ReservationStatus.completed => _Tone.secondary,
          ReservationStatus.cancelled => _Tone.neutral,
        };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // пара «фон / текст поверх фона»: по X пишут с onX
    final (background, foreground) = switch (_tone) {
      _Tone.primary => (scheme.primaryContainer, scheme.onPrimaryContainer),
      _Tone.secondary => (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer
        ),
      _Tone.tertiary => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      _Tone.neutral => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: foreground),
      ),
    );
  }
}
```

### UserAvatar — `lib/widgets/user_avatar.dart`

```dart
// widgets/user_avatar.dart — аватар с инициалами вместо фотографии.
import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class UserAvatar extends StatelessWidget {
  final User user;
  final double radius;

  const UserAvatar({super.key, required this.user, this.radius = 20});

  /// «Мария Попеску» → «МП», «Admin» → «A».
  String get _initials =>
      user.name.split(' ').where((p) => p.isNotEmpty).map((p) => p[0]).take(2).join();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      child: Text(
        _initials,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
```

---

## 5. История Git

Вывод `git log --oneline` (перед сдачей обновите командой ещё раз — в него попадут и последние commit-ы):

```
ca9ca7a Объединение с репозиторием PAMLab на GitHub
fb88eea Тема: seed заменён на зелёный (осознанное потребление, эко-тематика)
68d8cec Карточка вещи: кнопки «Написать» и «Забронировать» равной ширины (без переноса текста)
f5a4425 Минимальная навигация: NavigationBar на 4 вкладки, «Войти» ведёт на стартовый экран
e02fe27 Экран профиля: аватар, статистика, пункты настроек
46e3bcb Экран «Мои покупки»: брони пользователя со статусом каждой брони
8082243 Экран «Мои объявления»: список вещей пользователя со статусами
e5d6b98 L2 строго статично: карточка вещи показывает один mock-объект, ItemTile без onTap
8e779ac Экран ленты объявлений: поиск, фильтры по категории и размеру, сетка вещей
20b7ae3 Экран публикации объявления: форма добавления вещи (макет без валидации)
31aff2b Экран карточки вещи: фото, цена, размер, состояние, описание, продавец
7fcab9d Экран входа: статические поля e-mail/пароль и кнопка «Войти»
298c2c3 Визуальная тема Material 3: терракотовый seed, светлая и тёмная палитры
683e5b6 Переиспользуемые widget-ы: ItemCard, ItemTile, ItemPhoto, StatusBadge, UserAvatar
204ba1d Модель данных и mock-данные: Item, Reservation, User, Category
9693009 README: описание темы, экраны, модель данных, структура lib/
9b4421e Начальный проект: flutter create + структура lib/ (screens, widgets, data)
ed5417b Initial commit
```

---

## Вывод

В лабораторной работе создан Flutter-проект `second_hand_market` с разделением на
`screens/`, `widgets/` и `data/`, задана тема Material 3 через `ColorScheme.fromSeed` с
зелёным цветом домена (светлая и тёмная палитры) и построены в виде статического UI все
7 обязательных экранов темы с реалистичными mock-данными. Повторяющиеся элементы вынесены
в 5 переиспользуемых widget-ов. Работа велась инкрементально, с отдельным commit-ом на
каждый экран.
