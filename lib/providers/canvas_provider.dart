import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/canvas_model.dart';
import 'user_provider.dart';

/// Live stream of the couple's canvas document.
/// Resets to an empty message list whenever the stored date ≠ today.
final canvasStreamProvider = StreamProvider<CanvasModel?>((ref) {
  final me = ref.watch(currentUserProvider).valueOrNull;
  if (me?.coupleId == null) return Stream.value(null);
  final coupleId = me!.coupleId!;

  // Raw ref is used for writes; typed ref for reads
  final rawRef = ref.watch(firestoreProvider).collection('canvas').doc(coupleId);

  return rawRef.snapshots().asyncMap((snap) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (!snap.exists || (snap.data()?['date'] as String?) != today) {
      // New day — wipe the canvas
      await rawRef.set({'date': today, 'messages': <dynamic>[]});
      return CanvasModel(coupleId: coupleId, date: today, messages: []);
    }

    return CanvasModel.fromDoc(snap);
  });
});

/// Send a message to the canvas by appending to the Firestore array.
Future<void> sendCanvasMessage({
  required String coupleId,
  required String uid,
  required String text,
  required String color,
  required FirebaseFirestore firestore,
}) async {
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final message = CanvasMessage(
    uid: uid,
    text: text,
    color: color,
    timestamp: DateTime.now(),
  );
  await firestore.collection('canvas').doc(coupleId).update({
    'messages': FieldValue.arrayUnion([message.toMap()]),
    'date': today,
  });
}
