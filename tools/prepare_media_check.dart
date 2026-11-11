import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:gk_dnt_le_ngo_quoc_bo/services/image_processing.dart';
import 'package:gk_dnt_le_ngo_quoc_bo/services/excel_parser.dart';

void main() {
  final image = img.Image(width: 1200, height: 600)
    ..clear(img.ColorRgb8(100, 60, 200));
  image.exif.imageIfd.orientation = 6;
  final uri = prepareImage(Uint8List.fromList(img.encodeJpg(image)));
  final preview = parseExcel(
    File(
      'outputs/01a1c960-de00-73c2-b575-f2c01d7b1f74/products-template.xlsx',
    ).readAsBytesSync(),
  );
  if (!preview.valid) throw StateError(preview.errors.join('\n'));
  Directory('.tmp').createSync(recursive: true);
  File('.tmp/media-check-payload.json').writeAsStringSync(
    jsonEncode({
      'image': uri,
      'excel': preview.rows.map((r) => r.product!.toMap()).toList(),
    }),
  );
  stdout.writeln(
    'Prepared JPEG Data URI and ${preview.rows.length} validated XLSX rows.',
  );
}
