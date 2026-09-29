import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/catalog.dart';
import '../data/user.dart';
import '../models/favorites_model.dart';
import '../models/items_model.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/item_card.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ItemsModel>(); // watch в build
    final user = context.watch<User>();

    // три состояния экрана — на виду
    final Widget content;
    if (model.isLoading) {
      content = const Center(child: CircularProgressIndicator()); // 1) грузится
    } else if (model.error != null) {
      content = ErrorView(
        message: model.error!, // 2) упало
        onRetry: () => context.read<ItemsModel>().load(), // read: действие
      );
    } else {
      final items = model.feedFor(user); // 3) данные
      content = items.isEmpty
          ? const EmptyView(
              icon: Icons.checkroom, message: 'Пока нет объявлений')
          : GridView.builder(
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
            );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Лента'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => context.read<ItemsModel>().load(),
            icon: const Icon(Icons.refresh),
          ),
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
            labels: ['Все', for (final c in catalogCategories) c.name],
          ),
          _FilterRow(
            labels: ['Любой размер', ...catalogSizes],
          ),
          const SizedBox(height: 8),
          Expanded(child: content),
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
