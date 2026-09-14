// screens/item_details_screen.dart — Карточка вещи:
// фото, описание, цена, размер, состояние, продавец.
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../widgets/item_photo.dart';
import '../widgets/status_badge.dart';
import '../widgets/user_avatar.dart';

class ItemDetailsScreen extends StatelessWidget {
  const ItemDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // на L2 экран показывает один зашитый mock-объект;
    // передача выбранной вещи через маршрут — материал L3
    final item = mockItems.first;
    final seller = userById(item.ownerId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка вещи'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
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
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Написать'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () {}, // на L2 кнопки без эффекта
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
