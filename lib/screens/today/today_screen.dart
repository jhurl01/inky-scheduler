import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/events_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme.dart';
import '../../widgets/event_block.dart';
import '../../widgets/timeline_view.dart';

class TodayScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  const TodayScreen({super.key, this.initialDate});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  late DateTime _displayDate;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _displayDate = widget.initialDate ?? DateTime.now();
    // Update the shared provider so the FAB knows which date to default to
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(viewedDateProvider.notifier).state = _displayDate;
      _scrollToFocus();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Scroll ────────────────────────────────────────────────────────────────

  void _scrollToFocus() {
    final now = DateTime.now();
    final isToday = _displayDate.year == now.year &&
        _displayDate.month == now.month &&
        _displayDate.day == now.day;
    // Scroll to current hour (or 8am if before 8am and viewing today)
    final targetHour =
        isToday && now.hour >= kTimelineStartHour ? now.hour : 8;
    final offset =
        ((targetHour - kTimelineStartHour) * kHourHeight).clamp(0.0, double.infinity).toDouble();
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        offset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  // ── Date navigation ───────────────────────────────────────────────────────

  void _changeDate(DateTime date) {
    setState(() => _displayDate = date);
    ref.read(viewedDateProvider.notifier).state = date;
    // Brief delay so the list can rebuild before scrolling
    Future.delayed(const Duration(milliseconds: 50), _scrollToFocus);
  }

  void _stepDay(int delta) =>
      _changeDate(_displayDate.add(Duration(days: delta)));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _displayDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              Theme.of(ctx).colorScheme.copyWith(primary: kNearBlack),
        ),
        child: child!,
      ),
    );
    if (picked != null) _changeDate(picked);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    final events = ref.watch(eventsForDateProvider(_displayDate));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _DateHeader(
              date: _displayDate,
              onPrev: () => _stepDay(-1),
              onNext: () => _stepDay(1),
              onTapLabel: _pickDate,
            ),
            const Divider(height: 1),
            Expanded(
              child: TimelineView(
                events: events,
                currentUserId: me?.uid ?? '',
                selectedDate: _displayDate,
                scrollController: _scrollCtrl,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Date header ───────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTapLabel;

  const _DateHeader({
    required this.date,
    required this.onPrev,
    required this.onNext,
    required this.onTapLabel,
  });

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('EEEE · MMMM d').format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left, size: 22, color: kNearBlack),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          GestureDetector(
            onTap: onTapLabel,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: kNearBlack,
                letterSpacing: 0.2,
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right, size: 22, color: kNearBlack),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}
