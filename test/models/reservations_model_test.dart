import 'package:flutter_test/flutter_test.dart';

import 'package:second_hand_market/data/item.dart';
import 'package:second_hand_market/data/reservation.dart';
import 'package:second_hand_market/models/reservations_model.dart';

import '../support/fake_data.dart';
import '../support/fake_repositories.dart';

void main() {
  late FakeItemRepository items;
  late FakeReservationRepository repo;
  late ReservationsModel model;
  late List<Item> changed;

  setUp(() {
    items = FakeItemRepository();
    repo = FakeReservationRepository(items);
    changed = [];
    model = ReservationsModel(repo, userId: 'u1', onItemChanged: changed.add);
  });

  test('load: «грузится» -> «данные», два извещения', () async {
    final states = <bool>[];
    model.addListener(() => states.add(model.isLoading));

    await model.load();

    expect(states, [true, false]);
    expect(model.reservations.length, fakeReservations.length);
  });

  test('сбой сети: error, а потом retry возвращает данные', () async {
    repo.fail = true;
    await model.load();
    expect(model.error, offlineMessage);

    repo.fail = false;
    await model.load();

    expect(model.error, isNull);
    expect(model.reservations, isNotEmpty);
  });

  test('reserve: активная бронь сверху, вещь отдаётся наружу уже обновлённой',
      () async {
    await model.load();
    final item = items.find('i1')!;

    final error = await model.reserve(item);

    expect(error, isNull);
    expect(model.activeFor('i1'), isNotNull);
    expect(model.reservations.first.status, ReservationStatus.pending);
    expect(changed.single.status, ItemStatus.reserved);
  });

  test('повторная бронь той же вещи: сервер отказывает, состояние цело', () async {
    await model.load();
    await model.reserve(items.find('i1')!);
    final before = model.reservations.length;

    final error = await model.reserve(items.find('i1')!);

    expect(error, 'Вещь уже недоступна');
    expect(model.reservations.length, before);
  });

  test('cancel: бронь неактивна, вещь снова доступна', () async {
    await model.load();
    await model.reserve(items.find('i1')!);

    final error = await model.cancel(model.activeFor('i1')!);

    expect(error, isNull);
    expect(model.activeFor('i1'), isNull);
    expect(changed.last.status, ItemStatus.available);
  });

  test('completedCount считает только завершённые брони', () async {
    await model.load();

    expect(
      model.completedCount,
      fakeReservations
          .where((r) => r.status == ReservationStatus.completed)
          .length,
    );
  });

  test('reservations наружу read-only', () async {
    await model.load();

    expect(() => model.reservations.add(fakeReservations.first),
        throwsUnsupportedError);
  });
}
