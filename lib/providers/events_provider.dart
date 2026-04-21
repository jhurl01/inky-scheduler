import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_model.dart';
import 'user_provider.dart';

/// All events for the couple — real-time stream.
final eventsStreamProvider = StreamProvider<List<EventModel>>((ref) {
  final me = ref.watch(currentUserProvider).valueOrNull;
  if (me?.coupleId == null) return Stream.value([]);

  return ref
      .watch(firestoreProvider)
      .collection('events')
      .where('coupleId', isEqualTo: me!.coupleId)
      .snapshots()
      .map((snap) => snap.docs.map((d) => EventModel.fromDoc(d)).toList());
});

/// Client-side filter: events for a specific calendar date.
final eventsForDateProvider =
    Provider.family<List<EventModel>, DateTime>((ref, date) {
  final all = ref.watch(eventsStreamProvider).valueOrNull ?? [];
  return all
      .where((e) =>
          e.startTime.year == date.year &&
          e.startTime.month == date.month &&
          e.startTime.day == date.day)
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
});

/// Client-side filter: events for a specific calendar month.
final eventsForMonthProvider =
    Provider.family<List<EventModel>, DateTime>((ref, month) {
  final all = ref.watch(eventsStreamProvider).valueOrNull ?? [];
  return all
      .where((e) =>
          e.startTime.year == month.year &&
          e.startTime.month == month.month)
      .toList();
});

/// Find a single event by its Firestore document ID.
final eventByIdProvider =
    Provider.family<EventModel?, String>((ref, id) {
  final all = ref.watch(eventsStreamProvider).valueOrNull ?? [];
  try {
    return all.firstWhere((e) => e.id == id);
  } catch (_) {
    return null;
  }
});
