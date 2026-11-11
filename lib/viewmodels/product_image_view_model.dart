import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/image_value.dart';
import '../services/image_service.dart';
import '../services/error_message.dart';

enum ImageSourceChoice { url, file, camera }

class ProductImageViewModel extends ChangeNotifier {
  ProductImageViewModel(String initial, {ImageService? service})
    : service = service ?? ImageService() {
    value = initial;
    source = ImageValue.isData(initial)
        ? ImageSourceChoice.file
        : ImageSourceChoice.url;
    if (ImageValue.isHttps(initial)) {
      url = initial;
      changeUrl(initial);
    }
  }
  final ImageService service;
  late ImageSourceChoice source;
  String value = '';
  String url = '';
  String? error;
  bool loading = false;
  bool processing = false;
  bool verified = false;
  bool _disposed = false;
  int _generation = 0;
  Timer? _timer;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void changeUrl(String text) {
    _timer?.cancel();
    final generation = ++_generation;
    source = ImageSourceChoice.url;
    url = text.trim();
    value = '';
    verified = false;
    error = null;
    loading = url.isNotEmpty;
    _notify();
    if (url.isEmpty) return;
    _timer = Timer(const Duration(milliseconds: 500), () async {
      try {
        await service.validateUrl(url);
        if (_disposed || generation != _generation) return;
        value = url;
        verified = true;
      } catch (e) {
        if (_disposed || generation != _generation) return;
        error = errorMessage(e);
      } finally {
        if (!_disposed && generation == _generation) {
          loading = false;
          _notify();
        }
      }
    });
  }

  Future<void> chooseFile() => _replace(ImageSourceChoice.file, service.pick);
  Future<void> useCapture(Uint8List? bytes) async {
    if (bytes == null) return;
    await _replace(ImageSourceChoice.camera, () => service.process(bytes));
  }

  Future<void> _replace(
    ImageSourceChoice nextSource,
    Future<String?> Function() action,
  ) async {
    if (processing) return;
    processing = true;
    error = null;
    _notify();
    try {
      final next = await action();
      if (next != null && !_disposed) {
        _timer?.cancel();
        ++_generation;
        source = nextSource;
        value = next;
        verified = true;
        loading = false;
      }
    } catch (e) {
      if (!_disposed) error = errorMessage(e);
    } finally {
      processing = false;
      _notify();
    }
  }

  bool get canSave =>
      !processing &&
      !loading &&
      ImageValue.isValid(value) &&
      (ImageValue.isData(value) || verified);
  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    ++_generation;
    super.dispose();
  }
}
