import 'package:flutter/material.dart';

/// Small organic dot used as a calendar day-event marker.
/// Pass [color2] to render a horizontal split dot for paired events.
class InkDot extends StatelessWidget {
  final Color color;
  final Color? color2; // right half for paired events
  final double size;

  const InkDot({
    super.key,
    required this.color,
    this.color2,
    this.size = 6,
  });

  static const _radius = BorderRadius.only(
    topLeft: Radius.circular(3),
    topRight: Radius.circular(4),
    bottomLeft: Radius.circular(4),
    bottomRight: Radius.circular(3),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      child: ClipRRect(
        borderRadius: _radius,
        child: color2 != null
            ? Row(children: [
                Expanded(child: ColoredBox(color: color)),
                Expanded(child: ColoredBox(color: color2!)),
              ])
            : ColoredBox(color: color),
      ),
    );
  }
}
