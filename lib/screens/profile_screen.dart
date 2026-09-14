// screens/profile_screen.dart — Профиль пользователя.
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    // статистика считается по mock-данным
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
          Center(child: UserAvatar(user: currentUser, radius: 44)),
          const SizedBox(height: 12),
          Text(
            currentUser.name,
            textAlign: TextAlign.center,
            style: text.headlineSmall,
          ),
          Text(
            currentUser.email,
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
            onPressed: () {},
            icon: const Icon(Icons.logout),
            label: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}

/// Плитка статистики: число + подпись. Повторяется трижды на экране.
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
