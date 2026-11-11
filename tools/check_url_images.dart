import 'dart:io';
import 'package:gk_dnt_le_ngo_quoc_bo/services/url_image_native.dart';

Future<void> main() async {
  await validateUrlImage('https://www.gstatic.com/webp/gallery/1.jpg');
  stdout.writeln('Real HTTPS image URL decoded successfully.');
  try {
    await validateUrlImage('https://www.google.com/');
    throw StateError('HTML URL was accepted as an image.');
  } on FormatException {
    stdout.writeln('Real HTML page URL rejected as an image.');
  }
}
