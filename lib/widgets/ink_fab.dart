import 'package:flutter/material.dart';

import '../theme.dart';

/// Ink-drop shaped Floating Action Button.
/// The asymmetric corners mimic a falling ink drop.
class InkFab extends StatelessWidget {
  final VoidCallback onTap;

  const InkFab({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onTap,
      backgroundColor: kNearBlack,
      foregroundColor: kBackground,
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(4), // the "drip" corner
        ),
      ),
      child: const Icon(Icons.add, size: 26),
    );
  }
}
