import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/events_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme.dart';
import 'add_event_sheet.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(eventByIdProvider(eventId));
    final me = ref.watch(currentUserProvider).valueOrNull;
    final partner = ref.watch(partnerProvider).valueOrNull;

    if (event == null) {
      return Scaffold(
        appBar: AppBar(
          leading: _BackButton(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isOwn = event.ownerId == me?.uid;
    final ownerName =
        isOwn ? (me?.displayName ?? 'You') : (partner?.displayName ?? 'Partner');
    final accent = hexToColor(event.color);

    return Scaffold(
      appBar: AppBar(
        leading: _BackButton(),
        title: const Text('event'),
        actions: isOwn
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddEventSheet(
                      initialDate: event.startTime,
                      editingEvent: event,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () =>
                      _confirmDelete(context, ref, event.id),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color accent bar + title
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: kNearBlack,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Date & time
            _DetailRow(
              icon: Icons.schedule_outlined,
              text:
                  '${DateFormat('EEEE, MMM d').format(event.startTime)}\n'
                  '${DateFormat.jm().format(event.startTime)} – '
                  '${DateFormat.jm().format(event.endTime)}',
            ),

            // Location (if present)
            if (event.location != null && event.location!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DetailRow(
                  icon: Icons.location_on_outlined, text: event.location!),
            ],

            // Note (if present)
            if (event.note != null && event.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DetailRow(icon: Icons.notes_outlined, text: event.note!),
            ],

            const SizedBox(height: 24),

            // Owner attribution
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      topRight: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  ownerName,
                  style: const TextStyle(color: kMutedGray, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('delete event?',
            style: TextStyle(fontSize: 17, color: kNearBlack)),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: kMutedGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('cancel',
                style: TextStyle(color: kMutedGray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(firestoreProvider).collection('events').doc(id).delete();
      if (context.mounted) context.pop();
    }
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
      onPressed: () => context.canPop() ? context.pop() : context.go('/today'),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: kMutedGray),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 15, color: kNearBlack, height: 1.5),
          ),
        ),
      ],
    );
  }
}
