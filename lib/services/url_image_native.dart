import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../models/image_value.dart';

Future<void> validateUrlImage(String url) async {
  final client = http.Client();
  try {
    final response = await client
        .send(http.Request('GET', Uri.parse(url)))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw const FormatException(
        'Máy chủ không trả ảnh (HTTP không thành công).',
      );
    }
    final bytes = <int>[];
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 15),
    )) {
      bytes.addAll(chunk);
      if (bytes.length > ImageValue.maxInputBytes) {
        throw const FormatException('Ảnh URL vượt 5 MB để xem trước.');
      }
    }
    final info = img
        .findDecoderForData(bytes)
        ?.startDecode(Uint8List.fromList(bytes));
    if (info == null ||
        info.width <= 0 ||
        info.height <= 0 ||
        info.width * info.height > 32000000 ||
        img.decodeImage(Uint8List.fromList(bytes)) == null) {
      throw const FormatException(
        'URL không trả ảnh thực tế; không dùng URL trang HTML.',
      );
    }
  } finally {
    client.close();
  }
}
