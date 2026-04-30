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
  final String color; // owner's hex color, denormalized at creation
  final bool isPaired; // true when both partners are on this event
  final String? partnerColor; // partner's hex color, stored when isPaired

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
    this.isPaired = false,
    this.partnerColor,
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
      isPaired: d['isPaired'] as bool? ?? false,
      partnerColor: d['partnerColor'] as String?,
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
        'isPaired': isPaired,
        'partnerColor': partnerColor,
      };

  Duration get duration => endTime.difference(startTime);
}
