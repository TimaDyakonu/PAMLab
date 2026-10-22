import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/catalog.dart';
import '../models/favorites_model.dart';
import '../models/items_model.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/favorites_sheet.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/item_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Поиск происходит НА СЕРВЕРЕ: телефон получает только свои ломти.
  void _search(String query) =>
      context.read<ItemsModel>().load(search: query.trim());

  void _clearSearch() {
    _searchCtrl.clear();
    context.read<ItemsModel>().load(search: '');
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ItemsModel>(); // watch в build

    // три состояния экрана: на виду
    final Widget content;
    if (model.isLoading) {
      content = const Center(child: CircularProgressIndicator()); // 1) грузится
    } else if (model.error != null) {
      content = ErrorView(
        message: model.error!, // 2) упало
        onRetry: () => context.read<ItemsModel>().load(), // read: действие
      );
    } else {
      final items = model.feed; // 3) данные
      final searching = (model.search ?? '').isNotEmpty;
      content = items.isEmpty
          ? EmptyView(
              icon: searching ? Icons.search_off : Icons.checkroom,
              message: searching ? 'Ничего не найдено' : 'Пока нет объявлений',
            )
          : _FeedGrid(model: model);
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
            tooltip: 'Избранное',
            onPressed: () => FavoritesSheet.show(
              context,
              onOpen: (id) => context.push('/feed/$id'),
            ),
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
              controller: _searchCtrl,
              hintText: 'Поиск: джинсы, пальто, Zara…',
              leading: const Icon(Icons.search),
              onSubmitted: _search,
              onChanged: (_) => setState(() {}),
              trailing: [
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Сбросить поиск',
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.close),
                  ),
              ],
              elevation: const WidgetStatePropertyAll(0),
            ),
          ),
          FilterChipRow(
            labels: ['Все', for (final c in catalogCategories) c.name],
          ),
          FilterChipRow(
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

/// Сетка ленты с «хвостом»: последняя ячейка просит у модели следующую страницу.
class _FeedGrid extends StatelessWidget {
  final ItemsModel model;

  const _FeedGrid({required this.model});

  @override
  Widget build(BuildContext context) {
    final items = model.feed;
    final hasTail = model.hasMore || model.loadMoreError != null;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: items.length + (hasTail ? 1 : 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (context, index) {
        if (index == items.length) return _Tail(model: model);
        return ItemCard(
          item: items[index],
          onTap: () => context.push('/feed/${items[index].id}'),
        );
      },
    );
  }
}

class _Tail extends StatelessWidget {
  final ItemsModel model;

  const _Tail({required this.model});

  @override
  Widget build(BuildContext context) {
    if (model.loadMoreError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(model.loadMoreError!, textAlign: TextAlign.center),
            TextButton(
              onPressed: () => context.read<ItemsModel>().retryLoadMore(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    // Хвост просит следующую страницу прямо из build. Это запуск действия, а не
    // подписка, поэтому read; извещение внутри loadMore отложено до ответа.
    context.read<ItemsModel>().loadMore();
    return const Center(child: CircularProgressIndicator());
  }
}
