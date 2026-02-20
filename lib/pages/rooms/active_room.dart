import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import '../../providers/permissions_provider.dart';

class ActiveRoomPage extends ConsumerStatefulWidget {
  final String roomId;
  final String token;
  const ActiveRoomPage({super.key, required this.roomId, required this.token});

  @override
  ConsumerState<ActiveRoomPage> createState() => _ActiveRoomPageState();
}

class _ActiveRoomPageState extends ConsumerState<ActiveRoomPage> {
  Room? _room;
  late final EventsListener<RoomEvent> _listener;

  @override
  void initState() {
    super.initState();
    _initLiveKit();
  }

  Future<void> _initLiveKit() async {
  final room = Room();
  _listener = room.createListener();

  try {
    // 1. Connect
    // Note: In a production app, use: String url = dotenv.get('LIVEKIT_URL');
    await room.connect(dotenv.get('LIVEKIT_URL'), widget.token);
    
    // 2. Access the notifier to get the selected hardware
    final pNotifier = ref.read(permissionsProvider.notifier);

    // 3. TURN ON CAMERA with the selected device ID
    await room.localParticipant?.setCameraEnabled(
      true,
      cameraCaptureOptions: CameraCaptureOptions(
        deviceId: pNotifier.selectedCamera?.deviceId,
      ),
    );

    // 4. TURN ON MIC with the selected device ID
    await room.localParticipant?.setMicrophoneEnabled(
      true,
      audioCaptureOptions: AudioCaptureOptions(
        deviceId: pNotifier.selectedMic?.deviceId,
      ),
    );

    setState(() { _room = room; });
    
    // 5. Setup event listener for participants
    _listener.on<RoomEvent>((event) {
      if (event is ParticipantConnectedEvent || event is ParticipantDisconnectedEvent) {
        setState(() {}); // Rebuild the grid when people join/leave
      }
    });

  } catch (e) {
    debugPrint('Connection Error: $e');
  }
}

  @override
  void dispose() {
    _listener.dispose();
    _room?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_room == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Create a list of all participants (You + Others)
    final allParticipants = [
      _room!.localParticipant as Participant,
      ..._room!.remoteParticipants.values.cast<Participant>(),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GridView.builder(
            itemCount: allParticipants.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 columns for a clean look
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemBuilder: (context, index) {
              final participant = allParticipants[index];
              // This is the special widget provided by LiveKit to show video
              return ParticipantVideoView(participant: participant);
            },
          ),
          // Floating Control Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute/Unmute Mic
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: IconButton(
                      icon: Icon(
                        _room!.localParticipant!.isMicrophoneEnabled() ? Icons.mic : Icons.mic_off,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        final enabled = _room!.localParticipant!.isMicrophoneEnabled();
                        await _room!.localParticipant!.setMicrophoneEnabled(!enabled);
                        setState(() {}); // Update the icon color
                      },
                    ),
                  ),
                  
                  // End Call Button
                  CircleAvatar(
                    backgroundColor: Colors.red,
                    radius: 30,
                    child: IconButton(
                      icon: const Icon(Icons.call_end, color: Colors.white, size: 30),
                      onPressed: () {
                        _room?.disconnect();
                        context.pop(); // Go back to the meetings list
                      },
                    ),
                  ),

                  // Toggle Camera
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: IconButton(
                      icon: Icon(
                        _room!.localParticipant!.isCameraEnabled() ? Icons.videocam : Icons.videocam_off,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        final enabled = _room!.localParticipant!.isCameraEnabled();
                        await _room!.localParticipant!.setCameraEnabled(!enabled);
                        setState(() {}); // Update the icon color
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// A dedicated widget to render a single person's video
class ParticipantVideoView extends StatelessWidget {
  final Participant participant;
  const ParticipantVideoView({super.key, required this.participant});

  @override
  Widget build(BuildContext context) {
    // 1. Get the first video publication
    final pub = participant.videoTrackPublications.firstOrNull;
    final track = pub?.track;
    
    // 2. Check if the track exists and is a VideoTrack
    if (pub == null || track == null || track is! VideoTrack) {
      return Container(
        color: Colors.grey[900],
        child: Center(child: Text(participant.identity, style: const TextStyle(color: Colors.white))),
      );
    }

    // 3. Use VideoTrackRenderer with the correct cast
    return Stack(
      children: [
        VideoTrackRenderer(
          track,
          fit: VideoViewFit.cover, // Fills the square nicely
        ),
        // Overlay the name of the participant at the bottom
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: Colors.black54,
            child: Text(
              participant.identity,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }
}