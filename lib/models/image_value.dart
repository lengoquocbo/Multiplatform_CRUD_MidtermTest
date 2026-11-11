import 'dart:convert';

class ImageValue {
  static const maxInputBytes = 5 * 1024 * 1024;
  static const maxJpegBytes = 150 * 1024;
  static const prefix = 'data:image/jpeg;base64,';
  static const maxDataLength = 204823;
  static bool isHttps(String value) {
    final uri = Uri.tryParse(value);
    return value.length <= 2048 &&
        uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        !RegExp(r'\s').hasMatch(value);
  }

  static bool isData(String value) {
    if (!value.startsWith(prefix) || value.length > maxDataLength) return false;
    try {
      final bytes = base64Decode(value.substring(prefix.length));
      return bytes.length >= 4 &&
          bytes.length <= maxJpegBytes &&
          bytes[0] == 255 &&
          bytes[1] == 216 &&
          bytes[bytes.length - 2] == 255 &&
          bytes.last == 217;
    } catch (_) {
      return false;
    }
  }

  static bool isValid(String value) => isHttps(value) || isData(value);
}
