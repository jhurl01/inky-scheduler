import 'package:cloud_firestore/cloud_firestore.dart';

class CanvasMessage {
  final String uid;
  final String text;
  final String color; // hex — sender's accent color at time of sending
  final DateTime timestamp;

  const CanvasMessage({
    required this.uid,
    required this.text,
    required this.color,
    required this.timestamp,
  });

  factory CanvasMessage.fromMap(Map<String, dynamic> m) => CanvasMessage(
        uid: m['uid'] as String,
        text: m['text'] as String,
        color: m['color'] as String? ?? '#B8A9D9',
        timestamp: m['timestamp'] is Timestamp
            ? (m['timestamp'] as Timestamp).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'text': text,
        'color': color,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}

class CanvasModel {
  final String coupleId;
  final String date; // YYYY-MM-DD
  final List<CanvasMessage> messages;

  const CanvasModel({
    required this.coupleId,
    required this.date,
    required this.messages,
  });

  factory CanvasModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final raw = d['messages'] as List<dynamic>? ?? [];
    return CanvasModel(
      coupleId: doc.id,
      date: d['date'] as String? ?? '',
      messages: raw
          .map((m) => CanvasMessage.fromMap(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
