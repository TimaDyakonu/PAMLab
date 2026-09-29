import 'package:flutter_test/flutter_test.dart';

import 'package:second_hand_market/data/mock_network.dart';
import 'package:second_hand_market/data/mock_reservation_repository.dart';
import 'package:second_hand_market/data/reservation.dart';
import 'package:second_hand_market/models/reservations_model.dart';

void main() {
  late ReservationsModel model;

  setUp(() {
    model = ReservationsModel(
      MockReservationRepository(MockNetwork(latency: Duration.zero)),
    );
  });

  test('reserve создаёт активную бронь с id от хранилища', () async {
    await model.load();

    final error = await model.reserve('i1', 'u1');

    expect(error, isNull);
    final active = model.activeFor('i1');
    expect(active, isNotNull);
    expect(active!.status, ReservationStatus.pending);
    expect(active.id, isNot(''));
  });

  test('cancel делает бронь неактивной', () async {
    await model.load();
    await model.reserve('i1', 'u1');

    final error = await model.cancel(model.activeFor('i1')!);

    expect(error, isNull);
    expect(model.activeFor('i1'), isNull);
  });

  test('completedCount считает только завершённые брони', () async {
    await model.load();

    expect(
      model.completedCount,
      model.reservations
          .where((r) => r.status == ReservationStatus.completed)
          .length,
    );
  });
}
