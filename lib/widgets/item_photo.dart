// widgets/item_photo.dart: фотография вещи.
// Если у вещи есть загруженное на сервер фото (imageUrl), показываем его;
// иначе, или пока фото не пришло, иконка категории на приглушённом фоне.
// Заполняет ту коробку, которую ему дал родитель.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/api_config.dart';
import '../data/category.dart';

class ItemPhoto extends StatelessWidget {
  final Category category;
  final String imageUrl;
  final double iconSize;

  const ItemPhoto({
    super.key,
    required this.category,
    this.imageUrl = '',
    this.iconSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = _Placeholder(category: category, iconSize: iconSize);
    if (imageUrl.isEmpty) return placeholder;

    final config = context.watch<ApiConfig>();
    return Image.network(
      config.url(imageUrl),
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder,
      errorBuilder: (context, error, stack) => placeholder,
    );
  }
}

class _Placeholder extends StatelessWidget {
  final Category category;
  final double iconSize;

  const _Placeholder({required this.category, required this.iconSize});

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
