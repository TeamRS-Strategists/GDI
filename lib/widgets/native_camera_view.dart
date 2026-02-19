import 'package:flutter/material.dart';
import 'package:camera_macos/camera_macos.dart';

/// Singleton-style native camera view for macOS.
/// Uses the camera_macos package for zero-latency native preview.
class NativeCameraView extends StatefulWidget {
  const NativeCameraView({super.key});

  @override
  State<NativeCameraView> createState() => _NativeCameraViewState();
}

class _NativeCameraViewState extends State<NativeCameraView> {
  CameraMacOSController? _controller;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      // List available devices and pick the first video device
      final devices = await CameraMacOS.instance.listDevices(
        deviceType: CameraMacOSDeviceType.video,
      );

      if (devices.isEmpty) {
        if (mounted) {
          setState(() => _error = 'No camera found');
        }
        return;
      }

      debugPrint('[NativeCameraView] Found ${devices.length} camera(s), using: ${devices.first.localizedName}');
    } catch (e) {
      debugPrint('[NativeCameraView] Error listing devices: $e');
      if (mounted) {
        setState(() => _error = 'Camera init failed: $e');
      }
    }
  }

  void _onCameraCreated(CameraMacOSController controller) {
    _controller = controller;
    if (mounted) {
      setState(() => _isInitialized = true);
    }

    // Start the preview
    _controller!.startImageStream((image) {
      // We don't need frames — the native Texture handles rendering.
      // This just keeps the camera active.
    });
  }

  @override
  void dispose() {
    _controller?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorState(_error!);
    }

    return CameraMacOSView(
      fit: BoxFit.cover,
      cameraMode: CameraMacOSMode.photo, // continuous preview, no recording
      onCameraInizialized: _onCameraCreated,
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_rounded, size: 48, color: Colors.white.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
