// screens/my_purchases_screen.dart — Бронирование / мои покупки:
// брони текущего пользователя со статусом каждой брони.
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../widgets/item_tile.dart';
import '../widgets/status_badge.dart';

class MyPurchasesScreen extends StatelessWidget {
  const MyPurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои покупки')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mockReservations.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final reservation = mockReservations[index];
          final item = itemById(reservation.itemId);
          final seller = userById(item.ownerId);
          return ItemTile(
            item: item,
            // вместо статуса вещи — статус брони
            badge: StatusBadge.reservation(reservation.status),
            footer: '${seller.name} · бронь от '
                '${formatDate(reservation.createdAt)}',
          );
        },
      ),
    );
  }
}
