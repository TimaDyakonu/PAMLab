# second_hand_market

P2P-маркетплейс секонд-хенда: платформа для обмена и продажи одежды между
пользователями напрямую, без посредника-магазина.

Учебный проект по дисциплине «Программирование мобильных приложений» (PAM),
ТУМ, FCIM. Автор: Diaconu Timotei, группа TI-235.

## Экраны (по спецификации темы)

1. Вход / регистрация
2. Лента объявлений (поиск + фильтр по категории/размеру)
3. Карточка вещи (фото, описание, цена, размер, состояние, продавец)
4. Публикация объявления
5. Мои объявления
6. Бронирование / мои покупки (со статусом брони)
7. Профиль пользователя

## Модель данных

- `Item(id, title, description, price, size, condition, category, imageUrl, owner, status, createdAt)`
- `Reservation(id, itemId, buyerId, status, createdAt)`
- `User(id, name, email, avatarUrl)`
- `Category(id, name)`

## Структура `lib/`

```
lib/
├── main.dart     # корень композиции (выбор источника данных), тема, MaterialApp.router
├── router.dart   # карта маршрутов go_router
├── screens/      # по одному файлу на экран
├── widgets/      # переиспользуемые компоненты
├── models/       # ChangeNotifier-модели разделяемого состояния (чистый Dart)
└── data/         # сущности, Result, интерфейсы Repository, mock-реализации и seed
```

## Архитектура данных (L4)

```
экраны ──watch / read──▶ модели ChangeNotifier ──Future<Result<T>>──▶ Repository (интерфейс)
                                                                            ▲ implements
                                                                  MockItemRepository (L4)
                                                                  вариант на http     (L5)
```

- Экраны и widget-ы не знают источника данных: `grep -rn "mock_data" lib/screens lib/widgets lib/models` пуст.
- Источник выбирается в одном месте — `main()`; на L5 заменяется реализация repository и корень композиции.
- Три состояния на каждом экране с данными: загрузка → данные → ошибка с кнопкой «Повторить».
- Переключатель «Симулировать сбой сети» (профиль) включает аварию mock-а для демонстрации.

## Запуск

```bash
flutter pub get
flutter run
```
