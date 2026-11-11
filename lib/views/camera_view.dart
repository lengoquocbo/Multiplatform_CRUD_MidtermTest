import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../viewmodels/camera_view_model.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});
  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  final model = CameraViewModel();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    model.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive &&
        model.controller?.value.isInitialized == true) {
      model.release();
    }
    if (state == AppLifecycleState.resumed &&
        model.controller == null &&
        !model.starting) {
      model.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    model.dispose();
    super.dispose();
  }

  Future<void> capture() async {
    final bytes = await model.capture();
    if (bytes != null && mounted) {
      await model.release();
      if (mounted) Navigator.pop<Uint8List>(context, bytes);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => PopScope(
      canPop: !model.busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Chụp ảnh sản phẩm')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: model.starting
                      ? const CircularProgressIndicator()
                      : model.controller != null
                      ? CameraPreview(model.controller!)
                      : Text(
                          model.error ?? 'Không có camera.',
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
              if (model.error != null && model.controller != null)
                Text(model.error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed:
                        model.busy || model.starting || model.controller == null
                        ? null
                        : capture,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(model.busy ? 'Đang chụp…' : 'Chụp'),
                  ),
                  OutlinedButton(
                    onPressed: model.busy ? null : () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
