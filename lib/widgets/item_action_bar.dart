// widgets/item_action_bar.dart: нижняя панель действий на карточке вещи.
// Владельцу показывает «Удалить», покупателю: «Написать» и кнопку брони.
// Сам ничего не решает: состояние и действия приходят параметрами.
import 'package:flutter/material.dart';
import '../data/item.dart';
import 'button_spinner.dart';

class ItemActionBar extends StatelessWidget {
  final bool isOwner;
  final bool busy;
  final ItemStatus status;
  final bool hasActiveReservation;
  final VoidCallback onDelete;
  final VoidCallback onMessage;
  final VoidCallback onReserve;
  final VoidCallback onCancelReservation;

  const ItemActionBar({
    super.key,
    required this.isOwner,
    required this.busy,
    required this.status,
    required this.hasActiveReservation,
    required this.onDelete,
    required this.onMessage,
    required this.onReserve,
    required this.onCancelReservation,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: isOwner
            ? OutlinedButton.icon(
                onPressed: busy ? null : onDelete,
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
                      onPressed: onMessage,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Написать'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _reservationButton()),
                ],
              ),
      ),
    );
  }

  Widget _reservationButton() {
    if (busy) {
      return const FilledButton(onPressed: null, child: ButtonSpinner());
    }
    if (hasActiveReservation) {
      return FilledButton.tonal(
        onPressed: onCancelReservation,
        child: const Text('Отменить бронь'),
      );
    }
    final available = status == ItemStatus.available;
    return FilledButton(
      onPressed: available ? onReserve : null,
      child: Text(available ? 'Забронировать' : status.label),
    );
  }
}
