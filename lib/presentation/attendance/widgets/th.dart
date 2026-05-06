import 'package:flutter/material.dart';

class TH extends StatelessWidget {
  final String text;
  final bool center;
  const TH(this.text, {super.key, this.center = false});
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: 12,
      letterSpacing: 0.3,
    ),
    textAlign: center ? TextAlign.center : TextAlign.left,
  );
}
