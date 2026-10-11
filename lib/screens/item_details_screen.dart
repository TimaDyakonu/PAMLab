import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/item.dart';
import '../data/reservation.dart';
import '../data/user.dart';
import '../models/favorites_model.dart';
import '../models/items_model.dart';
import '../models/reservations_model.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/error_view.dart';
import '../widgets/item_action_bar.dart';
import '../widgets/item_info_card.dart';
import '../widgets/item_photo.dart';
import '../widgets/seller_card.dart';
import '../widgets/status_badge.dart';

class ItemDetailsScreen extends StatefulWidget {
  final String itemId;

  const ItemDetailsScreen({super.key, required this.itemId});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  // Эфемерное состояние: «запрос летит» видит только этот экран, поэтому setState.
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

    final ok = await ConfirmDialog.show(
      context,
      title: 'Удалить объявление?',
      message: '«${item.title}» исчезнет из ленты и из ваших объявлений.',
      confirmLabel: 'Удалить',
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    final error = await items.remove(item.id);
    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    messenger.showSnackBar(const SnackBar(content: Text('Объявление удалено')));
    context.pop(); // объекта больше нет, его экран уходит из стека
  }

  void _toggleFavorite(Item item, bool isFavorite) {
    // read в callback-е: действие, а не подписка
    context.read<FavoritesModel>().toggle(item.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite ? 'Убрано из избранного' : 'Добавлено в избранное',
        ),
      ),
    );
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
    final myReservation = reservations.activeFor(item.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка вещи'),
        actions: [
          IconButton(
            onPressed: () => _toggleFavorite(item, isFavorite),
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
                ItemInfoCard(item: item),
                const SizedBox(height: 16),
                Text('Описание', style: text.titleMedium),
                const SizedBox(height: 4),
                Text(item.description, style: text.bodyMedium),
                const SizedBox(height: 16),
                Text('Продавец', style: text.titleMedium),
                const SizedBox(height: 4),
                SellerCard(user: seller, onTap: () {}),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: ItemActionBar(
        isOwner: seller.id == user.id,
        busy: _busy,
        status: item.status,
        hasActiveReservation: myReservation != null,
        onDelete: () => _delete(item),
        onMessage: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Чат с продавцом откроется на L5')),
        ),
        onReserve: () => _reserve(item, user),
        onCancelReservation: () {
          if (myReservation != null) _cancelReservation(item, myReservation);
        },
      ),
    );
  }
}
