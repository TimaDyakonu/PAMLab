import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/mock_data.dart';
import '../widgets/item_tile.dart';

class MyItemsScreen extends StatelessWidget {
  const MyItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = myItems;

    return Scaffold(
      appBar: AppBar(title: const Text('Мои объявления')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => ItemTile(
          item: items[index],
          footer: '${items[index].size} · ${items[index].condition} · '
              'от ${formatDate(items[index].createdAt)}',
          onTap: () => context.push('/my-items/${items[index].id}'),
        ),
      ),
    );
  }
}

