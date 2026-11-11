import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../models/image_value.dart';

class CameraViewModel extends ChangeNotifier {
  CameraController? controller;
  String? error;
  bool starting = true;
  bool busy = false;
  bool _disposed = false;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> start() async {
    starting = true;
    error = null;
    _notify();
    try {
      final cameras = await availableCameras();
      if (_disposed) return;
      if (cameras.isEmpty) {
        throw const FormatException('Không tìm thấy camera trên thiết bị.');
      }
      final selected =
          cameras
              .where((c) => c.lensDirection == CameraLensDirection.back)
              .firstOrNull ??
          cameras.first;
      final next = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      controller = next;
      await next.initialize();
      if (_disposed) {
        await next.dispose();
        return;
      }
    } catch (e) {
      if (e is CameraException) {
        error = switch (e.code) {
          'CameraAccessDenied' ||
          'CameraAccessDeniedWithoutPrompt' ||
          'CameraAccessRestricted' =>
            'Quyền camera bị từ chối. Hãy cấp quyền camera trong cài đặt rồi mở lại.',
          _ =>
            'Không mở được camera (${e.code}). Web cần localhost hoặc HTTPS và thiết bị có webcam.',
        };
      } else {
        error = e is FormatException
            ? e.message
            : 'Không mở được webcam. Web cần localhost hoặc HTTPS.';
      }
      final current = controller;
      controller = null;
      await current?.dispose();
    } finally {
      starting = false;
      _notify();
    }
  }

  Future<Uint8List?> capture() async {
    if (busy || starting || controller == null) return null;
    busy = true;
    error = null;
    _notify();
    try {
      final file = await controller!.takePicture();
      if (await file.length() > ImageValue.maxInputBytes) {
        throw const FormatException(
          'Ảnh chụp vượt 5 MB. Chọn độ phân giải thấp hơn.',
        );
      }
      return await file.readAsBytes();
    } catch (e) {
      error = e is FormatException
          ? e.message
          : 'Không chụp được ảnh. Hãy thử lại.';
      return null;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> release() async {
    final current = controller;
    controller = null;
    await current?.dispose();
  }

  @override
  void dispose() {
    _disposed = true;
    final current = controller;
    controller = null;
    current?.dispose();
    super.dispose();
  }
}
