// widgets/status_badge.dart — бейдж статуса вещи или брони.
// Цвета берутся из ролей темы, а не зашиваются в код.
import 'package:flutter/material.dart';
import '../data/mock_data.dart';

enum _Tone { primary, secondary, tertiary, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final _Tone _tone;

  StatusBadge.item(ItemStatus status, {super.key})
      : label = status.label,
        _tone = switch (status) {
          ItemStatus.available => _Tone.primary,
          ItemStatus.reserved => _Tone.tertiary,
          ItemStatus.sold => _Tone.neutral,
        };

  StatusBadge.reservation(ReservationStatus status, {super.key})
      : label = status.label,
        _tone = switch (status) {
          ReservationStatus.pending => _Tone.tertiary,
          ReservationStatus.confirmed => _Tone.primary,
          ReservationStatus.completed => _Tone.secondary,
          ReservationStatus.cancelled => _Tone.neutral,
        };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // пара «фон / текст поверх фона»: по X пишут с onX
    final (background, foreground) = switch (_tone) {
      _Tone.primary => (scheme.primaryContainer, scheme.onPrimaryContainer),
      _Tone.secondary => (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer
        ),
      _Tone.tertiary => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      _Tone.neutral => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: foreground),
      ),
    );
  }
}
