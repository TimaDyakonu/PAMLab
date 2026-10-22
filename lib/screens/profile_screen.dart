import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/auth_api.dart';
import '../data/item.dart';
import '../models/favorites_model.dart';
import '../models/items_model.dart';
import '../models/reservations_model.dart';
import '../models/session_model.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/stat_card.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Выход: диалог -> токен стирается -> на login. Порядок важен: сначала
  // навигация, потом очистка сессии, чтобы экраны вкладок не перестроились
  // без пользователя.
  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthApi>();
    final session = context.read<SessionModel>();
    final router = GoRouter.of(context);

    final ok = await ConfirmDialog.show(
      context,
      title: 'Выйти из аккаунта?',
      message: 'Вы уверены, что хотите выйти?',
      confirmLabel: 'Да, выйти',
    );
    if (!ok) return;

    await auth.logout();
    router.go('/login');
    session.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final user = context.watch<SessionModel>().user;
    final items = context.watch<ItemsModel>();
    final reservations = context.watch<ReservationsModel>();
    final favorites = context.watch<FavoritesModel>();

    // статистика считается из моделей; пока данных нет, прочерк, а не нули
    final loaded = !items.isMineLoading &&
        items.mineError == null &&
        !reservations.isLoading &&
        reservations.error == null;
    final mine = items.mine;
    String stat(int Function() value) => loaded ? '${value()}' : '—';

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: UserAvatar(user: user, radius: 44)),
          const SizedBox(height: 12),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: text.headlineSmall,
          ),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  value: stat(() =>
                      mine.where((i) => i.status != ItemStatus.sold).length),
                  label: 'В продаже',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  value: stat(() =>
                      mine.where((i) => i.status == ItemStatus.sold).length),
                  label: 'Продано',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  value: stat(() => reservations.completedCount),
                  label: 'Покупок',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Личные данные'),
                  trailing: Icon(Icons.chevron_right),
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_border),
                  title: const Text('Избранное'),
                  trailing: Text('${favorites.count}', style: text.titleSmall),
                ),
                const ListTile(
                  leading: Icon(Icons.location_on_outlined),
                  title: Text('Город: Кишинёв'),
                  trailing: Icon(Icons.chevron_right),
                ),
                const ListTile(
                  leading: Icon(Icons.notifications_none),
                  title: Text('Уведомления'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}
