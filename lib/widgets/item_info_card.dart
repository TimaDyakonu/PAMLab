// widgets/item_info_card.dart: карточка с характеристиками вещи.
import 'package:flutter/material.dart';
import '../data/format_date.dart';
import '../data/item.dart';

class ItemInfoCard extends StatelessWidget {
  final Item item;

  const ItemInfoCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
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
            trailing: Text(item.condition, style: text.titleSmall),
          ),
          ListTile(
            leading: Icon(item.category.icon),
            title: const Text('Категория'),
            trailing: Text(item.category.name, style: text.titleSmall),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Опубликовано'),
            trailing: Text(formatDate(item.createdAt), style: text.titleSmall),
          ),
        ],
      ),
    );
  }
}
