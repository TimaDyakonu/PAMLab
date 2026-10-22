// widgets/photo_strip.dart: блок «Фотография» формы: выбор обложки объявления.
// Сам ничего не загружает: нажатие и состояние приходят параметрами.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/api_config.dart';
import 'button_spinner.dart';

class PhotoStrip extends StatelessWidget {
  /// Относительный путь загруженного фото, например «/files/7»; пусто: фото нет.
  final String imageUrl;

  /// Фото сейчас летит на сервер.
  final bool uploading;
  final VoidCallback onPick;

  const PhotoStrip({
    super.key,
    required this.imageUrl,
    required this.uploading,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Фотография', style: text.titleMedium),
        const SizedBox(height: 8),
        InkWell(
          onTap: uploading ? null : onPick,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 96,
            height: 96,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: _content(context, scheme),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          imageUrl.isEmpty
              ? 'Необязательно. Станет обложкой объявления.'
              : 'Фото загружено. Нажмите, чтобы заменить.',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _content(BuildContext context, ColorScheme scheme) {
    if (uploading) return const ButtonSpinner(size: 28);
    if (imageUrl.isEmpty) {
      return Icon(Icons.add_a_photo_outlined, color: scheme.onPrimaryContainer);
    }
    final config = context.watch<ApiConfig>();
    return Image.network(
      config.url(imageUrl),
      width: 96,
      height: 96,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) =>
          Icon(Icons.image_outlined, color: scheme.onPrimaryContainer),
    );
  }
}
