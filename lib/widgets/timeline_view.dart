import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/event_model.dart';
import '../theme.dart';
import 'event_block.dart';

// Timeline spans 7 am → 10 pm = 15 hours.
const int kTimelineEndHour = 22; // 10 pm (exclusive top of last slot)
const int kTotalHours = kTimelineEndHour - kTimelineStartHour; // 15
const double kLabelColumnWidth = 36.0;

/// Scrollable hourly timeline that renders [events] as absolute blocks.
/// [selectedDate] is used to decide whether to show the current-time indicator.
class TimelineView extends StatefulWidget {
  final List<EventModel> events;
  final String currentUserId;
  final DateTime selectedDate;
  final ScrollController scrollController;

  const TimelineView({
    super.key,
    required this.events,
    required this.currentUserId,
    required this.selectedDate,
    required this.scrollController,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  late Timer _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Refresh the current-time indicator every 30 seconds
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  bool get _isToday =>
      widget.selectedDate.year == _now.year &&
      widget.selectedDate.month == _now.month &&
      widget.selectedDate.day == _now.day;

  @override
  Widget build(BuildContext context) {
    // Total pixel height of the scrollable canvas
    const totalHeight = kTotalHours * kHourHeight;

    return LayoutBuilder(builder: (context, constraints) {
      const eventsColumnLeft = kLabelColumnWidth;
      final eventsColumnWidth = constraints.maxWidth - kLabelColumnWidth;

      return SingleChildScrollView(
        controller: widget.scrollController,
        child: SizedBox(
          height: totalHeight,
          child: Stack(
            children: [
              // ── Hour grid lines + labels ──────────────────────────────────
              ..._buildHourRows(totalHeight),

              // ── Event blocks ──────────────────────────────────────────────
              ...widget.events.map((e) => EventBlock(
                    event: e,
                    isOwn: e.ownerId == widget.currentUserId,
                    columnLeft: eventsColumnLeft,
                    columnWidth: eventsColumnWidth,
                    onTap: () =>
                        context.push('/event/${e.id}'),
                  )),

              // ── Current-time indicator (today only) ──────────────────────
              if (_isToday && _now.hour >= kTimelineStartHour &&
                  _now.hour < kTimelineEndHour)
                _CurrentTimeIndicator(
                  top: timeToOffset(_now),
                  width: constraints.maxWidth,
                  labelWidth: kLabelColumnWidth,
                ),
            ],
          ),
        ),
      );
    });
  }

  List<Widget> _buildHourRows(double totalHeight) {
    final rows = <Widget>[];
    for (int h = kTimelineStartHour; h <= kTimelineEndHour; h++) {
      // top of this hour slot in the stack
      final top = (h - kTimelineStartHour) * kHourHeight;
      rows.add(Positioned(
        top: top,
        left: 0,
        right: 0,
        child: _HourRow(hour: h, showLabel: h < kTimelineEndHour),
      ));
    }
    return rows;
  }
}

class _HourRow extends StatelessWidget {
  final int hour;
  final bool showLabel;

  const _HourRow({required this.hour, required this.showLabel});

  String get _label {
    if (!showLabel) return '';
    if (hour == 12) return '12 pm';
    if (hour < 12) return '$hour am';
    return '${hour - 12}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kHourHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label column
          SizedBox(
            width: kLabelColumnWidth,
            child: showLabel
                ? Padding(
                    padding: const EdgeInsets.only(top: 2, right: 6),
                    child: Text(
                      _label,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        color: kMutedGray,
                      ),
                    ),
                  )
                : null,
          ),
          // Horizontal divider
          const Expanded(
            child: Divider(
              height: 0,
              thickness: 0.5,
              color: kBorder,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width horizontal line with a small circle on the left.
/// Represents the current wall-clock time within the timeline.
class _CurrentTimeIndicator extends StatelessWidget {
  final double top;
  final double width;
  final double labelWidth;

  const _CurrentTimeIndicator({
    required this.top,
    required this.width,
    required this.labelWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top - 1, // center the 1dp line on the exact offset
      left: 0,
      width: width,
      child: Row(
        children: [
          // Circle sits at the left edge of the events column
          SizedBox(
            width: labelWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: kNearBlack.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: kNearBlack.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
