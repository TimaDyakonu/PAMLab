import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/format_date.dart';
import '../data/mock_data.dart';
import '../models/favorites_model.dart';
import '../widgets/item_photo.dart';
import '../widgets/status_badge.dart';
import '../widgets/user_avatar.dart';

class ItemDetailsScreen extends StatelessWidget {
  final String itemId;

  const ItemDetailsScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final item = itemById(itemId);
    final seller = item.owner;
    // watch в build: сердечко перерисовывается, когда избранное меняется
    final isFavorite = context.watch<FavoritesModel>().isFavorite(item.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка вещи'),
        actions: [
          IconButton(
            // read в callback-е: действие, а не подписка
            onPressed: () {
              context.read<FavoritesModel>().toggle(item.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isFavorite
                      ? 'Убрано из избранного'
                      : 'Добавлено в избранное'),
                ),
              );
            },
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? scheme.error : null,
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
        ],
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ItemPhoto(category: item.category, iconSize: 96),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.priceLabel,
                      style: text.headlineSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    StatusBadge.item(item.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.title, style: text.titleLarge),
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.straighten),
                        title: const Text('Размер'),
                        trailing: Text(item.size, style: text.titleSmall),
                      ),
                      ListTile(
                        leading: const Icon(Icons.auto_awesome_outlined),
                        title: const Text('Состояние'),
                        trailing:
                            Text(item.condition, style: text.titleSmall),
                      ),
                      ListTile(
                        leading: Icon(item.category.icon),
                        title: const Text('Категория'),
                        trailing:
                            Text(item.category.name, style: text.titleSmall),
                      ),
                      ListTile(
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: const Text('Опубликовано'),
                        trailing: Text(formatDate(item.createdAt),
                            style: text.titleSmall),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Описание', style: text.titleMedium),
                const SizedBox(height: 4),
                Text(item.description, style: text.bodyMedium),
                const SizedBox(height: 16),
                Text('Продавец', style: text.titleMedium),
                const SizedBox(height: 4),
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: UserAvatar(user: seller),
                    title: Text(seller.name),
                    subtitle: Text(seller.email),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Чат с продавцом откроется на L5')),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Написать'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Бронь отправлена: ${item.title}')),
                    );
                  },
                  child: const Text('Забронировать'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

