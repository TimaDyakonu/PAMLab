import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:second_hand_market/data/mock_data.dart';
import 'package:second_hand_market/data/mock_item_repository.dart';
import 'package:second_hand_market/data/mock_network.dart';
import 'package:second_hand_market/data/mock_reservation_repository.dart';
import 'package:second_hand_market/data/user.dart';
import 'package:second_hand_market/main.dart';
import 'package:second_hand_market/models/favorites_model.dart';
import 'package:second_hand_market/models/items_model.dart';
import 'package:second_hand_market/models/reservations_model.dart';

/// Приложение с тем же деревом провайдеров, что в main(), но без задержки
/// сети: тест не ждёт 800 мс на каждый вызов.
Widget buildTestApp({MockNetwork? network}) {
  final net = network ?? MockNetwork(latency: Duration.zero);
  final itemRepository = MockItemRepository(net);
  final reservationRepository = MockReservationRepository(net);

  return MultiProvider(
    providers: [
      Provider<MockNetwork>.value(value: net),
      Provider<User>.value(value: mockCurrentUser),
      ChangeNotifierProvider(create: (_) => ItemsModel(itemRepository)..load()),
      ChangeNotifierProvider(
        create: (_) => ReservationsModel(reservationRepository)..load(),
      ),
      ChangeNotifierProvider(create: (_) => FavoritesModel()),
    ],
    child: const MyApp(),
  );
}
