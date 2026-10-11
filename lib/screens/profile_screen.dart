import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/item.dart';
import '../data/mock_network.dart';
import '../data/user.dart';
import '../models/favorites_model.dart';
import '../models/items_model.dart';
import '../models/reservations_model.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/stat_card.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Эфемерное состояние: положение переключателя видит только этот экран.
  bool _simulateError = false;

  @override
  void initState() {
    super.initState();
    _simulateError = context.read<MockNetwork>().simulateError;
  }

  Future<void> _logout() async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Выйти из аккаунта?',
      message: 'Вы уверены, что хотите выйти?',
      confirmLabel: 'Да, выйти',
    );
    if (ok && mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final user = context.watch<User>();
    final items = context.watch<ItemsModel>();
    final reservations = context.watch<ReservationsModel>();
    final favorites = context.watch<FavoritesModel>();

    // статистика считается из моделей; пока данных нет — прочерк, не нули
    final loaded = !items.isLoading &&
        items.error == null &&
        !reservations.isLoading &&
        reservations.error == null;
    final mine = items.ownedBy(user);
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
          // Единственное место UI, которому позволено знать о mock-е:
          // леса демонстрации, умирают на L5 вместе с mock-ом.
          Card(
            margin: EdgeInsets.zero,
            child: SwitchListTile(
              secondary: const Icon(Icons.wifi_off),
              title: const Text('Симулировать сбой сети'),
              subtitle: const Text('Для демонстрации экрана ошибки'),
              value: _simulateError,
              onChanged: (value) {
                setState(() => _simulateError = value);
                context.read<MockNetwork>().simulateError = value;
              },
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}
