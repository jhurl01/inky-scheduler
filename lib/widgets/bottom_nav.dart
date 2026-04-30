import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/ui_state_provider.dart';
import '../screens/today/add_event_sheet.dart';
import '../theme.dart';

/// Flat five-slot bottom nav bar:
/// [Today] [Month] [  +  ] [Canvas] [Profile]
/// The center Add button opens the AddEvent sheet directly — no FAB notch.
class BottomNavBar extends ConsumerWidget {
  final String currentLocation;

  const BottomNavBar({super.key, required this.currentLocation});

  void _showAddEvent(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AddEventSheet(initialDate: date),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = _indexFrom(currentLocation);
    final viewedDate = ref.watch(viewedDateProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      color: kBackground,
      padding: EdgeInsets.only(bottom: bottomPad),
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
          // ── Center add button ──────────────────────────────────────
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showAddEvent(context, viewedDate),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 34,
                      decoration: BoxDecoration(
                        color: kNearBlack,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.add,
                          color: kBackground, size: 22),
                    ),
                    const SizedBox(height: 2),
                    // Empty label keeps vertical alignment with other items
                    const Text('', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ),
          ),
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
            label: 'Profile',
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
    return 0;
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
