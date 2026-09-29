import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/mock_data.dart';
import '../models/favorites_model.dart';
import '../widgets/item_card.dart';

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
            // Consumer: пересобирается только значок, а не весь экран
            icon: Consumer<FavoritesModel>(
              builder: (context, favorites, child) => Badge(
                isLabelVisible: favorites.count > 0,
                label: Text('${favorites.count}'),
                child: child!,
              ),
              child: const Icon(Icons.favorite_border),
            ),
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
          _FilterRow(
            labels: ['Все', for (final c in mockCategories) c.name],
          ),
          _FilterRow(
            labels: ['Любой размер', ...mockSizes],
          ),
          const SizedBox(height: 8),
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
                onTap: () => context.push('/feed/${items[index].id}'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/feed/new'),
        icon: const Icon(Icons.add),
        label: const Text('Продать'),
      ),
    );
  }
}

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

