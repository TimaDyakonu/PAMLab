// widgets/photo_strip.dart: блок «Фотографии» формы: кнопка добавления и
// заглушки для остальных фото. Реальный выбор фото появится позже.
import 'package:flutter/material.dart';

class PhotoStrip extends StatelessWidget {
  final int slots;

  const PhotoStrip({super.key, this.slots = 4});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Фотографии', style: text.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: slots,
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
      ],
    );
  }
}
