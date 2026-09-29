// widgets/favorites_sheet.dart — нижняя панель со списком избранного.
// Читает две модели: id избранного и сами вещи (у обеих свои состояния).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/favorites_model.dart';
import '../models/items_model.dart';
import 'empty_view.dart';
import 'error_view.dart';
import 'item_tile.dart';

class FavoritesSheet extends StatelessWidget {
  /// Вызывается с id вещи, когда пользователь тапнул по ней.
  final ValueChanged<String> onOpen;

  const FavoritesSheet({super.key, required this.onOpen});

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<String> onOpen,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => FavoritesSheet(
        onOpen: (id) {
          Navigator.pop(sheetCtx);
          onOpen(id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesModel>();
    final model = context.watch<ItemsModel>();

    final Widget body;
    if (model.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (model.error != null) {
      body = ErrorView(
        message: model.error!,
        onRetry: () => context.read<ItemsModel>().load(),
      );
    } else {
      final items = [
        for (final item in model.items)
          if (favorites.isFavorite(item.id)) item,
      ];
      body = items.isEmpty
          ? const EmptyView(
              icon: Icons.favorite_border,
              message: 'В избранном пусто.\nНажмите ♡ в карточке вещи.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => ItemTile(
                item: items[index],
                onTap: () => onOpen(items[index].id),
              ),
            );
    }

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: body,
    );
  }
}
