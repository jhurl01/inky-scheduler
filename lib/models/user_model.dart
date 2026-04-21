import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String color; // hex e.g. "#B8A9D9"
  final String? partnerId;
  final String? coupleId; // "${uidA}_${uidB}" — uids sorted alphabetically
  final String inviteCode; // 6-char alphanumeric

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.color,
    this.partnerId,
    this.coupleId,
    required this.inviteCode,
  });

  factory UserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return UserModel(
      uid: doc.id,
      displayName: d['displayName'] as String? ?? '',
      color: d['color'] as String? ?? '#B8A9D9',
      partnerId: d['partnerId'] as String?,
      coupleId: d['coupleId'] as String?,
      inviteCode: d['inviteCode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'color': color,
        'partnerId': partnerId,
        'coupleId': coupleId,
        'inviteCode': inviteCode,
      };

  UserModel copyWith({
    String? displayName,
    String? color,
    String? partnerId,
    String? coupleId,
    String? inviteCode,
  }) =>
      UserModel(
        uid: uid,
        displayName: displayName ?? this.displayName,
        color: color ?? this.color,
        partnerId: partnerId ?? this.partnerId,
        coupleId: coupleId ?? this.coupleId,
        inviteCode: inviteCode ?? this.inviteCode,
      );
}
