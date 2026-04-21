import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import 'auth_provider.dart';

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// Live stream of the signed-in user's Firestore document.
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authAsync = ref.watch(authStateProvider);
  return authAsync.when(
    data: (firebaseUser) {
      if (firebaseUser == null) return Stream.value(null);
      return ref
          .watch(firestoreProvider)
          .collection('users')
          .doc(firebaseUser.uid)
          .withConverter<UserModel>(
            fromFirestore: (snap, _) => UserModel.fromDoc(snap),
            toFirestore: (model, _) => model.toMap(),
          )
          .snapshots()
          .map((snap) => snap.exists ? snap.data() : null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Live stream of the partner's Firestore document (null until paired).
final partnerProvider = StreamProvider<UserModel?>((ref) {
  final me = ref.watch(currentUserProvider).valueOrNull;
  if (me?.partnerId == null) return Stream.value(null);
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(me!.partnerId)
      .withConverter<UserModel>(
        fromFirestore: (snap, _) => UserModel.fromDoc(snap),
        toFirestore: (model, _) => model.toMap(),
      )
      .snapshots()
      .map((snap) => snap.exists ? snap.data() : null);
});
