import 'package:cloud_firestore/cloud_firestore.dart';

class Meeting {
  final String id;
  final String roomName;
  final String hostId;
  final String hostEmail;
  final List<String> invitedUsers;
  final DateTime? createdAt;

  Meeting({
    required this.id,
    required this.roomName,
    required this.hostId,
    required this.hostEmail,
    required this.invitedUsers,
    this.createdAt,
  });

  /// Convert Firestore Document (Map) into a Meeting Object
  factory Meeting.fromMap(Map<String, dynamic> data, String id) {
    return Meeting(
      id: id,
      roomName: data['roomName'] ?? 'Untitled Room',
      hostId: data['hostId'] ?? '',
      hostEmail: data['hostEmail'] ?? '',
      // We cast the dynamic list from Firestore to a List of Strings
      invitedUsers: List<String>.from(data['invitedUsers'] ?? []),
      // Firestore stores dates as Timestamps, so we convert to Dart DateTime
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert Meeting Object into a Map to save/update in Firestore
  Map<String, dynamic> toMap() {
    return {
      'roomName': roomName,
      'hostId': hostId,
      'hostEmail': hostEmail,
      'invitedUsers': invitedUsers,
      // We use serverTimestamp so the date is set by the server, not the phone
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
    };
  }
}