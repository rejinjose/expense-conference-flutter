import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../models/meeting.dart';

// Provides the Cloud Functions instance
final functionsProvider = Provider((ref) => FirebaseFunctions.instance);

// Provides the MeetingService, automatically updating when the user logs in/out
final meetingServiceProvider = Provider((ref) {
  final firestore = FirebaseFirestore.instance;
  final functions = ref.watch(functionsProvider);
  final user = ref.watch(authStateProvider).value;

  return MeetingService(
    firestore, 
    functions, 
    user?.uid, 
    user?.email
  );
});

// A StreamProvider for the UI to listen to the list of meetings
final myMeetingsProvider = StreamProvider((ref) {
  return ref.watch(meetingServiceProvider).getMyMeetings();
});

class MeetingService {
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final String? _userId;
  final String? _userEmail;

  MeetingService(this._db, this._functions, this._userId, this._userEmail);

  // Helper to get a typed collection reference (just like your expense service)
  CollectionReference<Meeting> get _roomsRef =>
      _db.collection('rooms').withConverter<Meeting>(
            fromFirestore: (snapshot, _) =>
                Meeting.fromMap(snapshot.data()!, snapshot.id),
            toFirestore: (meeting, _) => meeting.toMap(),
          );

  // 1. Fetch Meetings (Translates RoomsList.tsx query)
  // Shows meetings where user is the Host OR is in the invitedUsers list
  Stream<List<Meeting>> getMyMeetings() {
    if (_userId == null || _userEmail == null) return Stream.value([]);

    return _db
        .collection('rooms')
        .where(Filter.or(
          Filter('hostId', isEqualTo: _userId),
          Filter('invitedUsers', arrayContains: _userEmail),
        ))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Meeting.fromMap(doc.data(), doc.id))
            .toList());
  }

  // 2. Create a Room (Translates CreateRoom.tsx)
  // Calls your 'createRoom' Cloud Function
  Future<String> createRoom(String roomName) async {
    final callable = _functions.httpsCallable('createRoom');
    final result = await callable.call({'roomName': roomName});
    return result.data['roomId'];
  }

  // 3. Get Single Room Details (Translates RoomDetails.tsx)
  Stream<Meeting> getRoomDetails(String roomId) {
    return _roomsRef.doc(roomId).snapshots().map((snap) => snap.data()!);
  }

  // 4. Invite Participant (Translates handleInvite in RoomDetails.tsx)
  Future<void> inviteParticipant(String roomId, String email) async {
    await _db.collection('rooms').doc(roomId).update({
      'invitedUsers': FieldValue.arrayUnion([email.trim()])
    });
  }

  // 5. Get LiveKit Token (Translates ActiveRoom.tsx)
  // Calls your 'getLiveKitToken' Cloud Function
  Future<String> getLiveKitToken(String roomId) async {
    final callable = _functions.httpsCallable('getLiveKitToken');
    final result = await callable.call({'roomId': roomId});
    return result.data['token'];
  }
}