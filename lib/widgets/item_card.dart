// widgets/item_card.dart — плитка вещи для сетки ленты.
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import 'item_photo.dart';
import 'status_badge.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;

  const ItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias, // фото обрезается по скруглённым углам
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // фото занимает всё, что осталось после текста
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ItemPhoto(category: item.category),
                  if (item.status != ItemStatus.available)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: StatusBadge.item(item.status),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.priceLabel,
                    style: text.titleMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.size} · ${item.condition}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

