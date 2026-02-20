import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/meeting_provider.dart';
import '../../providers/auth_provider.dart';
import '../../components/page_header.dart'; // Using your existing component

class MeetingsPage extends ConsumerWidget {
  const MeetingsPage({super.key});

  // Function to show the "Create Room" Dialog (Like your CreateRoom.tsx)
  void _showCreateRoomDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Meeting'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter Room Name (e.g. Daily Standup)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              
              Navigator.pop(context); // Close dialog
              
              // Call the Service we created earlier
              final roomId = await ref.read(meetingServiceProvider).createRoom(name);
              
              // Navigate to the permission check for that specific room
              if (context.mounted) {
                context.push('/permission/$roomId');
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to the stream of meetings
    final meetingsAsync = ref.watch(myMeetingsProvider);
    final user = ref.read(currentUserProvider); 

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          PageHeader(
            title: "Your Meetings",
            subtitle: "Join an existing room or create a new one:: ${user!.email}",
            action: ElevatedButton.icon(
              onPressed: () => _showCreateRoomDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text("New Room"),
            ),
          ),
          Expanded(
            child: meetingsAsync.when(
              data: (meetings) {
                if (meetings.isEmpty) {
                  return const Center(child: Text("No meetings found."));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: meetings.length,
                  itemBuilder: (context, index) {
                    final room = meetings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.video_call)),
                        title: Text(room.roomName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          "Created: ${room.createdAt != null ? DateFormat.yMMMd().add_jm().format(room.createdAt!) : 'Just now'}",
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigate to the details page for this room
                          context.push('/meeting/${room.id}');
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Error: $err")),
            ),
          ),
        ],
      ),
    );
  }
}