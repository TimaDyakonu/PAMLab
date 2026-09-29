import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/format_date.dart';
import '../data/item.dart';
import '../data/reservation.dart';
import '../data/user.dart';
import '../models/favorites_model.dart';
import '../models/items_model.dart';
import '../models/reservations_model.dart';
import '../widgets/error_view.dart';
import '../widgets/item_photo.dart';
import '../widgets/status_badge.dart';
import '../widgets/user_avatar.dart';

class ItemDetailsScreen extends StatefulWidget {
  final String itemId;

  const ItemDetailsScreen({super.key, required this.itemId});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  // Эфемерное состояние: «запрос летит» видит только этот экран — setState.
  bool _busy = false;

  Future<void> _reserve(Item item, User buyer) async {
    final reservations = context.read<ReservationsModel>();
    final items = context.read<ItemsModel>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);

    // На L5 обе записи сделает сервер одной транзакцией: POST /reservations.
    var error = await reservations.reserve(item.id, buyer.id);
    error ??= await items.update(item.copyWith(status: ItemStatus.reserved));

    if (!mounted) return; // экран может умереть, пока запрос летит
    setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'Бронь отправлена: ${item.title}')),
    );
  }

  Future<void> _cancelReservation(Item item, Reservation reservation) async {
    final reservations = context.read<ReservationsModel>();
    final items = context.read<ItemsModel>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);

    var error = await reservations.cancel(reservation);
    error ??= await items.update(item.copyWith(status: ItemStatus.available));

    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(SnackBar(content: Text(error ?? 'Бронь отменена')));
  }

  Future<void> _delete(Item item) async {
    final items = context.read<ItemsModel>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Удалить объявление?'),
        content: Text('«${item.title}» исчезнет из ленты и из ваших объявлений.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    final error = await items.remove(item.id);
    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    messenger.showSnackBar(const SnackBar(content: Text('Объявление удалено')));
    context.pop(); // объекта больше нет — его экран уходит из стека
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final model = context.watch<ItemsModel>(); // watch в build
    final user = context.watch<User>();
    final reservations = context.watch<ReservationsModel>();
    final isFavorite =
        context.watch<FavoritesModel>().isFavorite(widget.itemId);

    final item = model.byId(widget.itemId);
    if (item == null) {
      // у null два смысла: список ещё грузится, или такой вещи нет
      final Widget body;
      if (model.isLoading) {
        body = const Center(child: CircularProgressIndicator());
      } else if (model.error != null) {
        body = ErrorView(
          message: model.error!,
          onRetry: () => context.read<ItemsModel>().load(),
        );
      } else {
        body = const Center(child: Text('Вещи не существует'));
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Карточка вещи')),
        body: body,
      );
    }

    final seller = item.owner;
    final isOwner = seller.id == user.id;
    final myReservation = reservations.activeFor(item.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка вещи'),
        actions: [
          IconButton(
            // read в callback-е: действие, а не подписка
            onPressed: () {
              context.read<FavoritesModel>().toggle(item.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isFavorite
                      ? 'Убрано из избранного'
                      : 'Добавлено в избранное'),
                ),
              );
            },
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? scheme.error : null,
            ),
          ),
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
                  children: [
                    // Expanded: цена уступает место длинному бейджу, а не
                    // вызывает переполнение строки
                    Expanded(
                      child: Text(
                        item.priceLabel,
                        style: text.headlineSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
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
          child: isOwner
              ? OutlinedButton.icon(
                  onPressed: _busy ? null : () => _delete(item),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Удалить объявление'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    minimumSize: const Size.fromHeight(48),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Чат с продавцом откроется на L5'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Написать'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _busy
                          ? const FilledButton(
                              onPressed: null,
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            )
                          : myReservation != null
                              ? FilledButton.tonal(
                                  onPressed: () =>
                                      _cancelReservation(item, myReservation),
                                  child: const Text('Отменить бронь'),
                                )
                              : FilledButton(
                                  onPressed: item.status == ItemStatus.available
                                      ? () => _reserve(item, user)
                                      : null,
                                  child: Text(
                                    item.status == ItemStatus.available
                                        ? 'Забронировать'
                                        : item.status.label,
                                  ),
                                ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
