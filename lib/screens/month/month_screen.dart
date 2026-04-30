import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/canvas_model.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../providers/canvas_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme.dart';
import '../../widgets/ink_dot.dart';

class MonthScreen extends ConsumerStatefulWidget {
  const MonthScreen({super.key});

  @override
  ConsumerState<MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends ConsumerState<MonthScreen> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    final partner = ref.watch(partnerProvider).valueOrNull;
    final events = ref.watch(eventsStreamProvider).valueOrNull ?? [];
    final canvas = ref.watch(canvasStreamProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Screen title ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  DateFormat('MMMM').format(_focusedDay),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w300,
                    color: kNearBlack,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),

            // ── Calendar ──────────────────────────────────────────────────
            TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              onPageChanged: (day) => setState(() => _focusedDay = day),
              onDaySelected: (selected, focused) {
                final dateStr =
                    selected.toIso8601String().substring(0, 10);
                context.go('/day/$dateStr');
              },
              eventLoader: (day) => events
                  .where((e) => isSameDay(e.startTime, day))
                  .toList(),
              calendarBuilders: CalendarBuilders(
                // Custom dot markers below each day number
                markerBuilder: (ctx, day, dayEvents) {
                  final typed = dayEvents.cast<EventModel>();
                  return _DayMarkers(
                    events: typed,
                    me: me,
                    partner: partner,
                  );
                },
                // Today gets a filled near-black circle behind its number
                todayBuilder: (ctx, day, focusedDay) => _TodayCell(day: day),
                // Selected day: subtle highlight (we navigate immediately)
                selectedBuilder: (ctx, day, focusedDay) =>
                    _TodayCell(day: day, dimmed: true),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: kNearBlack,
                ),
                leftChevronIcon:
                    Icon(Icons.chevron_left, color: kNearBlack, size: 22),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: kNearBlack, size: 22),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                    fontSize: 12,
                    color: kMutedGray,
                    fontWeight: FontWeight.w500),
                weekendStyle: TextStyle(
                    fontSize: 12,
                    color: kMutedGray,
                    fontWeight: FontWeight.w500),
              ),
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle:
                    TextStyle(fontSize: 14, color: kNearBlack),
                weekendTextStyle:
                    TextStyle(fontSize: 14, color: kNearBlack),
                // todayDecoration and selectedDecoration overridden above via builders
                todayDecoration: BoxDecoration(),
                selectedDecoration: BoxDecoration(),
                markerDecoration: BoxDecoration(), // handled by builder
                markersMaxCount: 0, // prevent default markers
              ),
            ),

            const Divider(height: 1),

            // ── Canvas preview ────────────────────────────────────────────
            if (canvas != null) _CanvasPreview(canvas: canvas),
          ],
        ),
      ),
    );
  }
}

// ── Day markers ───────────────────────────────────────────────────────────────

class _DayMarkers extends StatelessWidget {
  final List<EventModel> events;
  final UserModel? me;
  final UserModel? partner;

  const _DayMarkers(
      {required this.events, required this.me, required this.partner});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    final hasPaired = events.any((e) => e.isPaired);
    final hasOwnOnly =
        events.any((e) => !e.isPaired && e.ownerId == me?.uid);
    final hasPartnerOnly = partner != null &&
        events.any((e) => !e.isPaired && e.ownerId == partner!.uid);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasPaired)
            InkDot(
              color: hexToColor(me?.color ?? '#B8A9D9'),
              color2: hexToColor(partner?.color ?? '#A9C9D9'),
            ),
          if (hasOwnOnly) InkDot(color: hexToColor(me?.color ?? '#B8A9D9')),
          if (hasPartnerOnly) InkDot(color: hexToColor(partner!.color)),
        ],
      ),
    );
  }
}

// ── Today cell ────────────────────────────────────────────────────────────────

class _TodayCell extends StatelessWidget {
  final DateTime day;
  final bool dimmed;
  const _TodayCell({required this.day, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: dimmed
              ? kNearBlack.withOpacity(0.12)
              : kNearBlack,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: dimmed ? kNearBlack : kBackground,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Canvas preview ─────────────────────────────────────────────────────────────

class _CanvasPreview extends StatelessWidget {
  final CanvasModel canvas;

  const _CanvasPreview({required this.canvas});

  @override
  Widget build(BuildContext context) {
    // Show the last 2 messages in chronological order
    final messages = canvas.messages.length > 2
        ? canvas.messages.sublist(canvas.messages.length - 2)
        : canvas.messages;

    return GestureDetector(
      onTap: () => context.go('/canvas'),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: kCardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'canvas',
                  style: TextStyle(
                      fontSize: 12,
                      color: kMutedGray,
                      fontWeight: FontWeight.w500),
                ),
                Text(
                  'open canvas →',
                  style: TextStyle(fontSize: 12, color: kMutedGray),
                ),
              ],
            ),
            if (messages.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'nothing here yet...',
                  style: TextStyle(
                      color: kMutedGray,
                      fontSize: 13,
                      fontStyle: FontStyle.italic),
                ),
              )
            else
              ...messages.map((m) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      m.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hexToColor(m.color),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
