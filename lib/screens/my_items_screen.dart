import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/format_date.dart';
import '../data/user.dart';
import '../models/items_model.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/item_tile.dart';

class MyItemsScreen extends StatelessWidget {
  const MyItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ItemsModel>(); // watch в build
    final user = context.watch<User>();

    final Widget body;
    if (model.isLoading) {
      body = const Center(child: CircularProgressIndicator()); // 1) грузится
    } else if (model.error != null) {
      body = ErrorView(
        message: model.error!, // 2) упало
        onRetry: () => context.read<ItemsModel>().load(), // read: действие
      );
    } else {
      final items = model.ownedBy(user); // 3) данные
      body = items.isEmpty
          ? const EmptyView(
              icon: Icons.sell_outlined,
              message: 'У вас пока нет объявлений.\nНажмите «Добавить».',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => ItemTile(
                item: items[index],
                footer: '${items[index].size} · ${items[index].condition} · '
                    'от ${formatDate(items[index].createdAt)}',
                onTap: () => context.push('/my-items/${items[index].id}'),
              ),
            );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Мои объявления')),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/my-items/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }
}
