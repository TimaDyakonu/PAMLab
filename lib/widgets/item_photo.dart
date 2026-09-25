// widgets/item_photo.dart — заглушка фотографии вещи.
// На L2 фото нет (imageUrl пуст): показываем иконку категории на
// приглушённом фоне. Заполняет ту коробку, которую ему дал родитель.
import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class ItemPhoto extends StatelessWidget {
  final Category category;
  final double iconSize;

  const ItemPhoto({super.key, required this.category, this.iconSize = 48});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        category.icon,
        size: iconSize,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

