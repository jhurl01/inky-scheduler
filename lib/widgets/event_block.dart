import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/event_model.dart';
import '../theme.dart';

const double kHourHeight = 64.0; // dp per hour — also used in timeline_view
const int kTimelineStartHour = 7; // 7 am

/// Returns the vertical offset (dp) of a given DateTime within the timeline.
double timeToOffset(DateTime time) =>
    (time.hour - kTimelineStartHour + time.minute / 60) * kHourHeight;

/// Returns the height (dp) of an event block from its duration.
double durationToHeight(Duration d) => (d.inMinutes / 60) * kHourHeight;

/// Absolutely-positioned colored event block inside the timeline stack.
class EventBlock extends StatelessWidget {
  final EventModel event;
  final bool isOwn;
  final double columnLeft;
  final double columnWidth;
  final VoidCallback onTap;

  const EventBlock({
    super.key,
    required this.event,
    required this.isOwn,
    required this.columnLeft,
    required this.columnWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final top = timeToOffset(event.startTime);
    final height =
        durationToHeight(event.duration).clamp(20.0, double.infinity);
    final accent = hexToColor(event.color);
    final accent2 = event.isPaired && event.partnerColor != null
        ? hexToColor(event.partnerColor!)
        : null;

    return Positioned(
      top: top,
      left: columnLeft + 4,
      width: columnWidth - 8,
      height: height,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: isOwn ? 1.0 : 0.6,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withOpacity(0.3), width: 0.5),
              gradient: accent2 != null
                  ? LinearGradient(
                      colors: [
                        accent.withOpacity(0.18),
                        accent2.withOpacity(0.18),
                      ],
                    )
                  : null,
              color: accent2 == null ? accent.withOpacity(0.15) : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar — split vertically for paired events
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: SizedBox(
                    width: 3,
                    child: accent2 != null
                        ? Column(children: [
                            Expanded(child: ColoredBox(color: accent)),
                            Expanded(child: ColoredBox(color: accent2)),
                          ])
                        : ColoredBox(color: accent),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: kNearBlack,
                          ),
                        ),
                        if (height > 36)
                          Text(
                            '${DateFormat.jm().format(event.startTime)} – '
                            '${DateFormat.jm().format(event.endTime)}',
                            style: const TextStyle(
                                fontSize: 11, color: kMutedGray),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
