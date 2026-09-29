import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/item.dart';
import '../data/mock_data.dart';
import '../data/reservation.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Да, выйти'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final onSale =
        myItems.where((i) => i.status != ItemStatus.sold).length;
    final sold = myItems.where((i) => i.status == ItemStatus.sold).length;
    final purchases = mockReservations
        .where((r) => r.status == ReservationStatus.completed)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: UserAvatar(user: mockCurrentUser, radius: 44)),
          const SizedBox(height: 12),
          Text(
            mockCurrentUser.name,
            textAlign: TextAlign.center,
            style: text.headlineSmall,
          ),
          Text(
            mockCurrentUser.email,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _StatCard(value: onSale, label: 'В продаже')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(value: sold, label: 'Продано')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(value: purchases, label: 'Покупок')),
            ],
          ),
          const SizedBox(height: 24),
          const Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Личные данные'),
                  trailing: Icon(Icons.chevron_right),
                ),
                ListTile(
                  leading: Icon(Icons.favorite_border),
                  title: Text('Избранное'),
                  trailing: Icon(Icons.chevron_right),
                ),
                ListTile(
                  leading: Icon(Icons.location_on_outlined),
                  title: Text('Город: Кишинёв'),
                  trailing: Icon(Icons.chevron_right),
                ),
                ListTile(
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

class _StatCard extends StatelessWidget {
  final int value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              '$value',
              style: text.headlineSmall?.copyWith(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: text.labelMedium
                  ?.copyWith(color: scheme.onSecondaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

