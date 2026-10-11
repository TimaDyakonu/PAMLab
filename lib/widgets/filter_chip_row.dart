// widgets/filter_chip_row.dart: горизонтальный ряд чипов-фильтров.
import 'package:flutter/material.dart';

class FilterChipRow extends StatelessWidget {
  final List<String> labels;

  const FilterChipRow({super.key, required this.labels});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => FilterChip(
          label: Text(labels[index]),
          selected: index == 0,
          onSelected: (_) {},
        ),
      ),
    );
  }
}
