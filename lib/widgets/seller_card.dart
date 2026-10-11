// widgets/seller_card.dart: карточка продавца (аватар, имя, e-mail).
import 'package:flutter/material.dart';
import '../data/user.dart';
import 'user_avatar.dart';

class SellerCard extends StatelessWidget {
  final User user;
  final VoidCallback? onTap;

  const SellerCard({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: UserAvatar(user: user),
        title: Text(user.name),
        subtitle: Text(user.email),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
