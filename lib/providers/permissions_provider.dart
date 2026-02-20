import 'package:flutter/material.dart' show WidgetsBindingObserver, WidgetsBinding, AppLifecycleState;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncNotifierProvider, AsyncNotifier, AsyncLoading, AsyncValue, AsyncData;
import 'package:livekit_client/livekit_client.dart' show MediaDevice, Hardware;
import 'package:permission_handler/permission_handler.dart' show Permission, PermissionStatusGetters, PermissionActions, PermissionListActions, openAppSettings;

// 1. Define the NotifierProvider using AsyncNotifier
final permissionsProvider = AsyncNotifierProvider<PermissionsNotifier, bool>(() {
  return PermissionsNotifier();
});

// 2. Define the Notifier class
class PermissionsNotifier extends AsyncNotifier<bool> with WidgetsBindingObserver {

  MediaDevice? selectedCamera;
  MediaDevice? selectedMic;

  @override
  Future<bool> build() async {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    return _checkCurrentStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check permissions when user returns to the app/tab
    if (state == AppLifecycleState.resumed) {
      refreshStatus();
    }
  }

  Future<bool> _checkCurrentStatus() async {
    final camera = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    final isGranted = camera.isGranted && mic.isGranted;
    if (isGranted) await _updateDeviceVariables();
    return isGranted;
  }

  // 3. Method to request permissions (replaces requestAll)
  Future<void> requestPermissions() async {
    // Set state to loading while the system popup is open
    state = const AsyncLoading();

    // Capture start time to detect browser suppression
    final startTime = DateTime.now();
    
    // Use AsyncValue.guard to catch any errors during the request
    state = await AsyncValue.guard(() async {
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      final duration = DateTime.now().difference(startTime);
      final isGranted = statuses.values.every((status) => status.isGranted);

      // HEURISTIC: If denied in less than 200ms on Web, the browser likely 
      // suppressed the popup because it was previously blocked.
      if (!isGranted && kIsWeb && duration.inMilliseconds < 200) {
        // You can throw a custom error or handle via a side-effect
        throw 'BROWSER_SUPPRESSED'; 
      }

      // ONLY call openAppSettings if NOT on web
      if (!kIsWeb) {
        if (statuses[Permission.camera]!.isPermanentlyDenied || 
            statuses[Permission.microphone]!.isPermanentlyDenied) {
          await openAppSettings();
        }
      }

      return isGranted;
    });
  }

  Future<void> refreshStatus() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _checkCurrentStatus());
  }

  Future<void> _updateDeviceVariables() async {
    selectedCamera = Hardware.instance.selectedVideoInput;
    selectedMic = Hardware.instance.selectedAudioInput;
  }

  Future<void> loadSelectedDevices() async {
    await _updateDeviceVariables();
    state = AsyncData(state.value ?? false);
  }
}


