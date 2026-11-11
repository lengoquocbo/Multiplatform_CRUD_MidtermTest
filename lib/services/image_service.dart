export 'image_processing.dart' show prepareImage;
import 'image_processing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/image_value.dart';
import 'url_image_native.dart'
    if (dart.library.js_interop) 'url_image_web.dart'
    as url_loader;

class ImageService {
  Future<String?> pick() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null) return null;
    final file = result.files.single;
    if (file.size > ImageValue.maxInputBytes || file.bytes == null) {
      throw const FormatException('Chọn ảnh tối đa 5 MB.');
    }
    return process(file.bytes!);
  }

  Future<String> process(Uint8List bytes) => compute(prepareImage, bytes);
  Future<void> validateUrl(String url) async {
    if (!ImageValue.isHttps(url)) {
      throw const FormatException('Nhập URL HTTPS hợp lệ, tối đa 2048 ký tự.');
    }
    await url_loader.validateUrlImage(url);
  }
}
