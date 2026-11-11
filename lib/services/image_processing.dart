import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/image_value.dart';

String prepareImage(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > ImageValue.maxInputBytes) {
    throw const FormatException('Ảnh đầu vào phải nhỏ hơn hoặc bằng 5 MB.');
  }
  final info = img.findDecoderForData(bytes)?.startDecode(bytes);
  if (info == null ||
      info.width <= 0 ||
      info.height <= 0 ||
      info.width * info.height > 32000000) {
    throw const FormatException(
      'File không phải ảnh được hỗ trợ hoặc ảnh vượt 32 triệu pixel.',
    );
  }
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Không đọc được dữ liệu ảnh thực tế.');
  }
  var result = img.bakeOrientation(decoded);
  final longest = math.max(result.width, result.height);
  if (longest > 800) {
    result = img.copyResize(
      result,
      width: math.max(1, (result.width * 800 / longest).round()),
      height: math.max(1, (result.height * 800 / longest).round()),
      interpolation: img.Interpolation.average,
    );
  }
  final background = img.Image(
    width: result.width,
    height: result.height,
    numChannels: 3,
  )..clear(img.ColorRgb8(255, 255, 255));
  result = img.compositeImage(background, result);
  for (var pass = 0; pass < 12; pass++) {
    for (final quality in [90, 80, 70, 60, 50, 40, 30]) {
      final jpeg = img.encodeJpg(result, quality: quality);
      if (jpeg.length <= ImageValue.maxJpegBytes) {
        return ImageValue.prefix + base64Encode(jpeg);
      }
    }
    result = img.copyResize(
      result,
      width: math.max(1, (result.width * .8).round()),
      height: math.max(1, (result.height * .8).round()),
    );
  }
  throw const FormatException('Không thể nén ảnh xuống 150 KB.');
}
