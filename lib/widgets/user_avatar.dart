// widgets/user_avatar.dart — аватар с инициалами вместо фотографии.
import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class UserAvatar extends StatelessWidget {
  final User user;
  final double radius;

  const UserAvatar({super.key, required this.user, this.radius = 20});

  /// «Мария Попеску» → «МП», «Admin» → «A».
  String get _initials =>
      user.name.split(' ').where((p) => p.isNotEmpty).map((p) => p[0]).take(2).join();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      child: Text(
        _initials,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
