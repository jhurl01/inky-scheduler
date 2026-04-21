import 'package:flutter/material.dart';

/// Small organic dot used as a calendar day-event marker.
/// Slightly asymmetric border radius gives it an inky, hand-drawn feel.
class InkDot extends StatelessWidget {
  final Color color;
  final double size;

  const InkDot({
    super.key,
    required this.color,
    this.size = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(3),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(3),
        ),
      ),
    );
  }
}
