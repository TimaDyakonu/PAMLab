// screens/new_item_screen.dart — Публикация объявления.
// Макет формы: TextField / DropdownMenu / Switch без валидации
// и без сохранения — это придёт на L3–L5.
import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class NewItemScreen extends StatelessWidget {
  const NewItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Новое объявление')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Фотографии', style: text.titleMedium),
          const SizedBox(height: 8),
          // место под фото: горизонтальный ряд, как у ленты фильтров
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => Container(
                width: 96,
                decoration: BoxDecoration(
                  color: index == 0
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  index == 0 ? Icons.add_a_photo_outlined : Icons.image_outlined,
                  color: index == 0
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'До 5 фото. Первое станет обложкой объявления.',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Название',
              hintText: 'Например: Джинсы Levi\'s 501',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Описание',
              hintText: 'Материал, дефекты, как сидит',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownMenu<String>(
            expandedInsets: EdgeInsets.zero, // на всю ширину
            label: const Text('Категория'),
            dropdownMenuEntries: [
              for (final c in mockCategories)
                DropdownMenuEntry(value: c.id, label: c.name),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownMenu<String>(
                  expandedInsets: EdgeInsets.zero,
                  label: const Text('Размер'),
                  dropdownMenuEntries: [
                    for (final s in mockSizes)
                      DropdownMenuEntry(value: s, label: s),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownMenu<String>(
                  expandedInsets: EdgeInsets.zero,
                  label: const Text('Состояние'),
                  dropdownMenuEntries: [
                    for (final c in mockConditions)
                      DropdownMenuEntry(value: c, label: c),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Цена',
              suffixText: 'MDL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Готов(а) к обмену'),
            subtitle: const Text('Покупатель может предложить свою вещь'),
            value: true,
            onChanged: (_) {},
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Опубликовать'),
          ),
        ],
      ),
    );
  }
}
