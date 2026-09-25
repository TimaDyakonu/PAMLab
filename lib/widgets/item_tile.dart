// widgets/item_tile.dart — строка вещи для списков
// («Мои объявления», «Мои покупки»).
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import 'item_photo.dart';
import 'status_badge.dart';

class ItemTile extends StatelessWidget {
  final Item item;

  /// Бейдж справа внизу. По умолчанию — статус самой вещи;
  /// на экране покупок сюда передаётся статус брони.
  final Widget? badge;

  /// Дополнительная строка под названием (продавец, дата брони…).
  final String? footer;

  final VoidCallback? onTap;

  const ItemTile({
    super.key,
    required this.item,
    this.badge,
    this.footer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 72,
                child: ItemPhoto(category: item.category, iconSize: 32),
              ),
            ),
            const SizedBox(width: 12),
            // Expanded: реальный предел ширины — длинное название
            // переносится, а не вызывает переполнение
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    footer ?? '${item.size} · ${item.condition}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      badge ?? StatusBadge.item(item.status),
                      Text(
                        item.priceLabel,
                        style: text.titleMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

