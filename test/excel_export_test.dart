import 'dart:convert';
import 'dart:math';
import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';
import 'package:gk_dnt_le_ngo_quoc_bo/models/product.dart';
import 'package:gk_dnt_le_ngo_quoc_bo/services/excel_export_service.dart';
import 'package:gk_dnt_le_ngo_quoc_bo/services/excel_parser.dart';

void main() {
  test(
    'Ảnh Data URI lớn được nhúng JPEG đầy đủ ở cột image, không cắt chuỗi',
    () {
      final image = img.Image(width: 200, height: 200);
      final random = Random(1);
      for (final pixel in image) {
        pixel.setRgb(
          random.nextInt(256),
          random.nextInt(256),
          random.nextInt(256),
        );
      }
      final jpeg = img.encodeJpg(image, quality: 90);
      final uri = 'data:image/jpeg;base64,${base64Encode(jpeg)}';
      expect(uri.length, greaterThan(32767));
      final p = Product(
        id: 'id',
        name: 'Ảnh chụp',
        price: 1,
        soluong: 1,
        image: uri,
      );
      final bytes = buildProductsXlsx([p]);
      final zip = ZipDecoder().decodeBytes(bytes);
      expect(zip.findFile('xl/media/image1.jpg')!.content, orderedEquals(jpeg));
      expect(
        utf8.decode(
          zip.findFile('xl/drawings/drawing1.xml')!.content as List<int>,
        ),
        contains('<xdr:col>3</xdr:col>'),
      );
      expect(parseExcel(bytes).errors.join(' '), contains('ảnh nhúng'));
    },
  );
  test('Xuất XLSX đúng bốn cột, nhập lại và giữ số lớn', () {
    const p = Product(
      id: 'not-exported',
      name: '=Tên & <bút>',
      price: 12500.5,
      soluong: 9007199254740991,
      image: 'https://example.com/image',
    );
    final bytes = buildProductsXlsx([p]);
    final book = Excel.decodeBytes(bytes);
    expect(
      book.tables.values.first.rows.first
          .map((c) => c!.value.toString())
          .toList(),
      ['name', 'price', 'soluong', 'image'],
    );
    final preview = parseExcel(bytes);
    expect(preview.valid, isTrue);
    expect(preview.rows.single.product!.toMap(), p.toMap());
    expect(book.tables.values.first.rows[1][0]!.value, isA<TextCellValue>());
  });
  test('Danh sách trống vẫn tạo file Excel có tiêu đề', () {
    final book = Excel.decodeBytes(buildProductsXlsx([]));
    expect(book.tables.values.first.rows.length, 1);
  });
  test('Không âm thầm cắt dữ liệu quá giới hạn ô Excel', () {
    final p = Product(
      id: 'id',
      name: 'a' * 32768,
      price: 1,
      soluong: 1,
      image: 'https://example.com/image',
    );
    expect(() => buildProductsXlsx([p]), throwsFormatException);
  });
}
