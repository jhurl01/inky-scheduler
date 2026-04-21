import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';

/// Bottom app bar with four navigation destinations arranged around the
/// center FAB notch: [Today] [Month]  ●FAB●  [Canvas] [You].
/// The spec names the four items as Today, Month, Add (center), You; Canvas
/// is included here because it has its own dedicated screen.
class BottomNavBar extends StatelessWidget {
  final String currentLocation;

  const BottomNavBar({super.key, required this.currentLocation});

  @override
  Widget build(BuildContext context) {
    final idx = _indexFrom(currentLocation);
    return BottomAppBar(
      color: kBackground,
      elevation: 0,
      height: 62,
      notchMargin: 6,
      shape: const CircularNotchedRectangle(),
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          _NavItem(
            icon: Icons.calendar_today_outlined,
            activeIcon: Icons.calendar_today,
            label: 'Today',
            active: idx == 0,
            onTap: () => context.go('/today'),
          ),
          _NavItem(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view,
            label: 'Month',
            active: idx == 1,
            onTap: () => context.go('/month'),
          ),
          // Spacer creates the notch gap for the FAB
          const Expanded(child: SizedBox()),
          _NavItem(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            label: 'Canvas',
            active: idx == 2,
            onTap: () => context.go('/canvas'),
          ),
          _NavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'You',
            active: idx == 3,
            onTap: () => context.go('/you'),
          ),
        ],
      ),
    );
  }

  int _indexFrom(String loc) {
    if (loc.startsWith('/month')) return 1;
    if (loc.startsWith('/canvas')) return 2;
    if (loc.startsWith('/you')) return 3;
    return 0; // /today, /day/:date, /event/:id
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? kNearBlack : kMutedGray;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? activeIcon : icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
