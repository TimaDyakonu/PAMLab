import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/format_date.dart';
import '../models/items_model.dart';
import '../models/reservations_model.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/item_tile.dart';
import '../widgets/status_badge.dart';

class MyPurchasesScreen extends StatelessWidget {
  const MyPurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // экран читает две модели: брони и вещи, на которые они ссылаются
    final reservations = context.watch<ReservationsModel>();
    final items = context.watch<ItemsModel>();

    final Widget body;
    if (reservations.isLoading || items.isLoading) {
      body = const Center(child: CircularProgressIndicator()); // 1) грузится
    } else if (reservations.error != null || items.error != null) {
      body = ErrorView(
        message: reservations.error ?? items.error!, // 2) упало
        onRetry: () {
          context.read<ReservationsModel>().load(); // read: действие
          context.read<ItemsModel>().load();
        },
      );
    } else {
      final rows = [
        for (final r in reservations.reservations)
          if (items.byId(r.itemId) != null) (r, items.byId(r.itemId)!),
      ]; // 3) данные
      body = rows.isEmpty
          ? const EmptyView(
              icon: Icons.shopping_bag_outlined,
              message: 'Покупок пока нет.\nЗабронируйте вещь в ленте.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final (reservation, item) = rows[index];
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
