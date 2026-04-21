import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String ownerId;
  final String coupleId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? note;
  final String color; // hex — denormalized from owner's color at creation time

  const EventModel({
    required this.id,
    required this.ownerId,
    required this.coupleId,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.location,
    this.note,
    required this.color,
  });

  factory EventModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return EventModel(
      id: doc.id,
      ownerId: d['ownerId'] as String,
      coupleId: d['coupleId'] as String,
      title: d['title'] as String,
      startTime: (d['startTime'] as Timestamp).toDate(),
      endTime: (d['endTime'] as Timestamp).toDate(),
      location: d['location'] as String?,
      note: d['note'] as String?,
      color: d['color'] as String? ?? '#B8A9D9',
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'coupleId': coupleId,
        'title': title,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'location': location,
        'note': note,
        'color': color,
      };

  Duration get duration => endTime.difference(startTime);
}
