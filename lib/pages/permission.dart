import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/permissions_provider.dart' show permissionsProvider;
import '../providers/meeting_provider.dart';

class PermissionPage extends ConsumerWidget {
  final String roomId; 
  const PermissionPage({super.key, required this.roomId});

  void _showWebHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera/Mic is Blocked'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You previously blocked access. To fix this:'),
            SizedBox(height: 10),
            Text('1. Click the **Camera/Lock icon** in your browser address bar.'),
            Text('2. Change the setting for Camera and Mic to **Allow**.'),
            Text('3. Refresh the page.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionState = ref.watch(permissionsProvider);

    ref.listen(permissionsProvider, (previous, next) {

      // Listen for the specific suppression error
      if (next is AsyncError && next.error == 'BROWSER_SUPPRESSED') {
        if (context.mounted) {
          _showWebHelpDialog(context);
        }
      }

      next.whenData((isGranted) async {
        // Logic to detect if we should show the web dialog
        if (!isGranted && kIsWeb) {
          final camera = await Permission.camera.status;
          final mic = await Permission.microphone.status;
          if (context.mounted && (camera.isPermanentlyDenied || mic.isPermanentlyDenied)) {
            _showWebHelpDialog(context);
          }
        }
      });
    });

    return Scaffold(
      body: permissionState.when(
        data: (isGranted) {
          if (isGranted) {
            final notifier = ref.read(permissionsProvider.notifier);
            final cameraName = notifier.selectedCamera?.label ?? "Default Camera";
            final micName = notifier.selectedMic?.label ?? "Default Microphone";
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 20),
                  const Text("All systems ready!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  
                  // Device Info Cards
                  _deviceTile(Icons.videocam, "Camera", cameraName),
                  _deviceTile(Icons.mic, "Microphone", micName),
                  
                  const SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: () async {
                      // 1. Get the token from our service
                      final service = ref.read(meetingServiceProvider);
                      final token = await service.getLiveKitToken(roomId);
                      
                      // 2. Navigate to the actual LiveKit Room
                      if (context.mounted) {
                        context.push('/room/$roomId', extra: token);
                      }
                    },
                    child: const Text("Enter Meeting Room"),
                  ),

                  const SizedBox(height: 30),
                  
                  // Instructional Text
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text(
                      "Note: To switch devices, use your system settings or click the browser's camera icon in the address bar.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => ref.read(permissionsProvider.notifier).requestPermissions(),
                    child: const Text("Grant Permissions"),
                  ),
                  if (kIsWeb) ...[
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => _showWebHelpDialog(context),
                      child: const Text("Need help enabling camera?"),
                    ),
                  ],
                ],
              ),
            );
          }
        },
        loading: () => const CircularProgressIndicator(),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                e == 'BROWSER_SUPPRESSED' 
                  ? "Permission popup blocked by browser." 
                  : "Error: $e",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref.read(permissionsProvider.notifier).requestPermissions(),
                child: const Text("Try Again"),
              ),
              if (kIsWeb) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => _showWebHelpDialog(context),
                  child: const Text("Show Instructions"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


Widget _deviceTile(IconData icon, String title, String deviceName) {
  return ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(deviceName, style: const TextStyle(color: Colors.grey)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 40),
  );
}