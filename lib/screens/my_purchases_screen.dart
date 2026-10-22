import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/format_date.dart';
import '../models/reservations_model.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/item_tile.dart';
import '../widgets/status_badge.dart';

class MyPurchasesScreen extends StatelessWidget {
  const MyPurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ReservationsModel>(); // watch в build

    final Widget body;
    if (model.isLoading) {
      body = const Center(child: CircularProgressIndicator()); // 1) грузится
    } else if (model.error != null) {
      body = ErrorView(
        message: model.error!, // 2) упало
        onRetry: () => context.read<ReservationsModel>().load(), // read: действие
      );
    } else {
      final reservations = model.reservations; // 3) данные
      body = reservations.isEmpty
          ? const EmptyView(
              icon: Icons.shopping_bag_outlined,
              message: 'Покупок пока нет.\nЗабронируйте вещь в ленте.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reservations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final reservation = reservations[index];
                final item = reservation.item; // вещь приходит вместе с бронью
                return ItemTile(
                  item: item,
                  badge: StatusBadge.reservation(reservation.status),
                  footer: '${item.owner.name} · бронь от '
                      '${formatDate(reservation.createdAt)}',
                  onTap: () => context.push('/purchases/${item.id}'),
                );
              },
            );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Мои покупки')),
      body: body,
    );
  }
}
