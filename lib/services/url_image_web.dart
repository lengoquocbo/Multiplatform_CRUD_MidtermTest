import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> validateUrlImage(String url) async {
  final image = web.HTMLImageElement()..referrerPolicy = 'no-referrer';
  try {
    image.src = url;
    await image.decode().toDart.timeout(const Duration(seconds: 15));
    if (image.naturalWidth <= 0 || image.naturalHeight <= 0) {
      throw const FormatException('URL không trả ảnh thực tế.');
    }
  } catch (_) {
    throw const FormatException(
      'Không tải được ảnh từ URL. Có thể URL là trang HTML, nguồn chặn tải ảnh hoặc mạng bị lỗi.',
    );
  } finally {
    image.src = '';
  }
}
