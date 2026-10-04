import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChanged;

  const RatingStars({required this.value, this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
        children: List.generate(5, (index) {
      final active = index < value;
      return IconButton(
        onPressed: onChanged == null ? null : () => onChanged!(index + 1),
        icon: Icon(active ? Icons.star_rounded : Icons.star_border_rounded,
            color: active ? Colors.amber : Colors.grey),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
    }));
  }
}
