// screens/feed_screen.dart — Лента объявлений:
// поиск + фильтр по категории и размеру (на L2 — только визуально,
// работать фильтры начнут на L4, когда появится состояние).
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../widgets/item_card.dart';
import 'item_details_screen.dart';
import 'new_item_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = feedItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Лента'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SearchBar(
              hintText: 'Поиск: джинсы, пальто, Zara…',
              leading: const Icon(Icons.search),
              trailing: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.tune)),
              ],
              elevation: const WidgetStatePropertyAll(0),
            ),
          ),
          // ряды фильтров длиннее экрана → горизонтальный scroll
          _FilterRow(
            labels: ['Все', for (final c in mockCategories) c.name],
          ),
          _FilterRow(
            labels: ['Любой размер', ...mockSizes],
          ),
          const SizedBox(height: 8),
          // Expanded даёт сетке конечную высоту — остаток экрана
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              itemBuilder: (context, index) => ItemCard(
                item: items[index],
                // временная навигация для демонстрации (Задание 6)
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ItemDetailsScreen(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewItemScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Продать'),
      ),
    );
  }
}

/// Горизонтальный ряд фильтров; первый чип выбран (статично).
class _FilterRow extends StatelessWidget {
  final List<String> labels;

  const _FilterRow({required this.labels});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => FilterChip(
          label: Text(labels[index]),
          selected: index == 0,
          onSelected: (_) {},
        ),
      ),
    );
  }
}
