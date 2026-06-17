import 'package:flutter/material.dart';

class Chips extends StatelessWidget {
  final String value, label;
  final Color color;
  final VoidCallback? onTap;
  final bool selected;

  const Chips({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgOpacity = selected ? 0.18 : 0.08;
    final borderOpacity = selected ? 0.6 : 0.25;

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: color.withOpacity(bgOpacity),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: color.withOpacity(borderOpacity),
          width: selected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );

    if (onTap == null) return chip;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.0),
      child: chip,
    );
  }
}