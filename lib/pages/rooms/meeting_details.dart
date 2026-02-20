import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/meeting_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/meeting.dart';
import '../../components/page_header.dart'; // Using your existing component

class MeetingDetailsPage extends ConsumerStatefulWidget {
  final String roomId;
  const MeetingDetailsPage({super.key, required this.roomId});

  @override
  ConsumerState<MeetingDetailsPage> createState() => _MeetingDetailsPageState();
}

class _MeetingDetailsPageState extends ConsumerState<MeetingDetailsPage> {
  final _inviteEmailController = TextEditingController();
  bool _isInviting = false;

  @override
  void dispose() {
    _inviteEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleInvite(WidgetRef ref) async {
    final email = _inviteEmailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isInviting = true);
    try {
      final service = ref.read(meetingServiceProvider);
      await service.inviteParticipant(widget.roomId, email);
      _inviteEmailController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Participant invited successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to invite: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isInviting = false);
    }
  }

  

  @override
  Widget build(BuildContext context) {
    final meetingService = ref.watch(meetingServiceProvider);
    final currentUser = ref.read(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Details'),
      ),
      body: StreamBuilder<Meeting>(
        stream: meetingService.getRoomDetails(widget.roomId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final meeting = snapshot.data;
          if (meeting == null) {
            return const Center(child: Text("Meeting not found."));
          }

          final isHost = currentUser?.uid == meeting.hostId;
          print('Meeting details');
          print(widget.roomId);
          print(meeting.id);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: meeting.roomName,
                  subtitle: "Hosted by: ${meeting.hostEmail}",
                  action: ElevatedButton.icon(
                    onPressed: () => context.push('/permission/${widget.roomId}'),
                    icon: const Icon(Icons.video_camera_front),
                    label: const Text("Join Meeting"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Meeting Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Meeting Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text("Room ID: ${meeting.id}", style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text("Created: ${meeting.createdAt != null ? DateFormat.yMMMd().add_jm().format(meeting.createdAt!) : 'N/A'}"),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Host Only Section: Invite Participants
                if (isHost) ...[
                  const Text("Invite Participants", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inviteEmailController,
                          decoration: const InputDecoration(
                            hintText: 'Enter participant email',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isInviting ? null : () => _handleInvite(ref),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                        child: _isInviting 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text("Invite"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Invited Users List
                const Text("Invited Participants", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: meeting.invitedUsers.length,
                  itemBuilder: (context, index) {
                    final email = meeting.invitedUsers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueGrey.shade100,
                          child: const Icon(Icons.person, color: Colors.blueGrey),
                        ),
                        title: Text(email),
                        trailing: email == meeting.hostEmail 
                            ? const Chip(label: Text('Host', style: TextStyle(fontSize: 12)))
                            : null,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}