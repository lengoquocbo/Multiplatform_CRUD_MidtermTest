import 'package:archive/archive.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:gk_dnt_le_ngo_quoc_bo/models/image_value.dart';
import 'package:gk_dnt_le_ngo_quoc_bo/models/product.dart';
import 'package:gk_dnt_le_ngo_quoc_bo/repositories/product_repository.dart';
import 'package:gk_dnt_le_ngo_quoc_bo/services/image_service.dart';
import 'package:gk_dnt_le_ngo_quoc_bo/services/excel_service.dart';
import 'package:gk_dnt_le_ngo_quoc_bo/viewmodels/product_image_view_model.dart';
import 'package:gk_dnt_le_ngo_quoc_bo/viewmodels/excel_import_view_model.dart';

class ImageTestService extends ImageService {
  int calls = 0;
  bool failed = false;
  @override
  Future<void> validateUrl(String url) async {
    calls++;
    if (failed) throw const FormatException('URL là HTML');
  }

  @override
  Future<String?> pick() async => null;
}

class ExcelTestService extends ExcelService {
  ExcelTestService(this.bytes);
  final Uint8List bytes;
  @override
  Future<Uint8List?> pick() async => bytes;
}

class ImportTestRepository extends Fake implements ProductRepository {
  final List<Product> stored = [];
  int calls = 0;
  @override
  String newId() => 'generated-${calls++}';
  @override
  Future<List<Product>> fetchServer() async => [
    const Product(
      id: 'existing',
      name: 'Bút',
      price: 1,
      soluong: 1,
      image: 'https://example.com/a',
    ),
  ];
  @override
  Future<void> save(Product product, {required bool creating}) async {
    if (stored.length == 1) throw StateError('Lỗi kiểm thử ở hàng thứ hai');
    stored.add(product);
  }
}

Uint8List excelBytes(List<List<CellValue?>> values) {
  final book = Excel.createExcel();
  final sheet = book.tables.values.first;
  for (final row in values) {
    sheet.appendRow(row);
  }
  return Uint8List.fromList(book.encode()!);
}

void main() {
  test(
    'Ảnh sửa EXIF, giữ tỉ lệ, cạnh dài <=800, JPEG <=150KB và chỉ lưu Data URI',
    () {
      final input = img.Image(width: 1200, height: 600)
        ..clear(img.ColorRgb8(45, 100, 200));
      input.exif.imageIfd.orientation = 6;
      final result = prepareImage(Uint8List.fromList(img.encodeJpg(input)));
      expect(ImageValue.isData(result), isTrue);
      final bytes = base64Decode(result.substring(ImageValue.prefix.length));
      final output = img.decodeJpg(bytes)!;
      expect(output.width, 400);
      expect(output.height, 800);
      expect(bytes.length, lessThanOrEqualTo(ImageValue.maxJpegBytes));
      expect(
        Product(
          id: 'id',
          name: 'Ảnh',
          price: 0,
          soluong: 0,
          image: result,
        ).toMap().length,
        4,
      );
    },
  );
  test('Ảnh nhiễu được giảm chất lượng/kích thước đến tối đa 150 KB', () {
    final image = img.Image(width: 800, height: 800);
    final random = Random(42);
    for (final pixel in image) {
      pixel.setRgb(
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
      );
    }
    final uri = prepareImage(Uint8List.fromList(img.encodePng(image)));
    final jpeg = base64Decode(uri.substring(ImageValue.prefix.length));
    expect(jpeg.length, lessThanOrEqualTo(ImageValue.maxJpegBytes));
    final decoded = img.decodeJpg(jpeg)!;
    expect(decoded.width, lessThanOrEqualTo(800));
    expect(decoded.width, decoded.height);
  });
  test('Chặn file giả ảnh, >5MB, Data URI sai và URL quá dài', () {
    expect(
      () => prepareImage(
        Uint8List.fromList(utf8.encode('<html>not an image</html>')),
      ),
      throwsFormatException,
    );
    expect(
      () => prepareImage(Uint8List(ImageValue.maxInputBytes + 1)),
      throwsFormatException,
    );
    expect(ImageValue.isValid('data:image/jpeg;base64,YWJj'), isFalse);
    expect(ImageValue.isValid('blob:https://example.com/x'), isFalse);
    expect(ImageValue.isHttps('https://example.com/${'a' * 2048}'), isFalse);
  });
  testWidgets('URL debounce 500ms; HTML lỗi; hủy chọn/chụp giữ ảnh cũ', (
    tester,
  ) async {
    final service = ImageTestService();
    final vm = ProductImageViewModel('', service: service);
    vm.changeUrl('https://example.com/a');
    await tester.pump(const Duration(milliseconds: 499));
    expect(service.calls, 0);
    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();
    expect(vm.value, 'https://example.com/a');
    await vm.chooseFile();
    await vm.useCapture(null);
    expect(vm.value, 'https://example.com/a');
    service.failed = true;
    vm.changeUrl('https://example.com/html');
    await tester.pump(const Duration(milliseconds: 501));
    await tester.pump();
    expect(vm.canSave, isFalse);
    expect(vm.error, contains('HTML'));
    vm.dispose();
  });
  test(
    'Excel ánh xạ đảo cột, trim, bỏ hàng trống và báo lỗi công thức/kiểu theo ô',
    () {
      final valid = excelBytes([
        [
          TextCellValue('image'),
          TextCellValue('soluong'),
          TextCellValue('name'),
          TextCellValue('price'),
        ],
        [
          TextCellValue(' https://example.com/a '),
          IntCellValue(2),
          TextCellValue(' Bút '),
          DoubleCellValue(1.5),
        ],
        [null, null, null, null],
      ]);
      final preview = parseExcel(valid);
      expect(preview.valid, isTrue);
      expect(preview.rows.length, 1);
      expect(preview.rows.single.product!.name, 'Bút');
      final bad = parseExcel(
        excelBytes([
          [
            TextCellValue('name'),
            TextCellValue('price'),
            TextCellValue('soluong'),
            TextCellValue('image'),
          ],
          [
            TextCellValue('Bút'),
            FormulaCellValue('1+1'),
            DoubleCellValue(1.5),
            TextCellValue('data:image/jpeg;base64,AA'),
          ],
        ]),
      );
      expect(bad.valid, isFalse);
      expect(bad.errors.join(' '), contains('B2'));
      expect(bad.errors.join(' '), contains('C (soluong)'));
      expect(bad.errors.join(' '), contains('D (image)'));
    },
  );
  test('Chỉ từ chối ảnh nhúng thật, không từ chối drawing trống', () {
    final bytes = excelBytes([
      [
        TextCellValue('name'),
        TextCellValue('price'),
        TextCellValue('soluong'),
        TextCellValue('image'),
      ],
      [
        TextCellValue('Bút'),
        IntCellValue(1),
        IntCellValue(1),
        TextCellValue('https://example.com/a'),
      ],
    ]);
    expect(parseExcel(bytes).valid, isTrue);
    final source = ZipDecoder().decodeBytes(bytes);
    final output = Archive();
    for (final file in source.files) {
      if (file.name == 'xl/drawings/drawing1.xml') {
        final data = utf8.encode(
          utf8
              .decode(file.content as List<int>)
              .replaceFirst('/>', '><xdr:pic/></xdr:wsDr>'),
        );
        output.addFile(ArchiveFile(file.name, data.length, data));
      } else {
        output.addFile(file);
      }
    }
    final result = parseExcel(Uint8List.fromList(ZipEncoder().encode(output)!));
    expect(result.valid, isFalse);
    expect(result.errors.join(' '), contains('ảnh nhúng'));
  });
  test('Bỏ ô trống đã format ở hàng xa và giữ số hàng dữ liệu thật', () {
    final bytes = excelBytes([
      [
        TextCellValue('name'),
        TextCellValue('price'),
        TextCellValue('soluong'),
        TextCellValue('image'),
      ],
      [
        TextCellValue('Bút'),
        IntCellValue(1),
        IntCellValue(1),
        TextCellValue('https://example.com/a'),
      ],
    ]);
    final source = ZipDecoder().decodeBytes(bytes);
    final archive = Archive();
    for (final file in source.files) {
      if (file.name == 'xl/worksheets/sheet1.xml') {
        final data = utf8.encode(
          utf8
              .decode(file.content as List<int>)
              .replaceFirst(
                '</sheetData>',
                '<row r="2000"><c r="A2000" s="1"/></row></sheetData>',
              ),
        );
        archive.addFile(ArchiveFile(file.name, data.length, data));
      } else {
        archive.addFile(file);
      }
    }
    final result = parseExcel(
      Uint8List.fromList(ZipEncoder().encode(archive)!),
    );
    expect(result.valid, isTrue);
    expect(result.rows.single.number, 2);
  });
  test('Ảnh rất hẹp không tạo kích thước bằng không', () {
    final image = img.Image(width: 1, height: 2000);
    final uri = prepareImage(Uint8List.fromList(img.encodePng(image)));
    final output = img.decodeJpg(
      base64Decode(uri.substring(ImageValue.prefix.length)),
    )!;
    expect(output.width, 1);
    expect(output.height, 800);
  });
  test('Excel mẫu xuất thật đọc được đúng bốn cột', () {
    final preview = parseExcel(
      File(
        'outputs/01a1c960-de00-73c2-b575-f2c01d7b1f74/products-template.xlsx',
      ).readAsBytesSync(),
    );
    expect(preview.errors, isEmpty);
    expect(preview.rows.length, 2);
  });
  test(
    'Nhập Excel cảnh báo trùng, chặn nhập lại và báo số đã xác nhận khi lỗi giữa chừng',
    () async {
      final bytes = excelBytes([
        [
          TextCellValue('name'),
          TextCellValue('price'),
          TextCellValue('soluong'),
          TextCellValue('image'),
        ],
        [
          TextCellValue('Bút'),
          IntCellValue(1),
          IntCellValue(1),
          TextCellValue('https://example.com/a'),
        ],
        [
          TextCellValue('Bút'),
          IntCellValue(2),
          IntCellValue(2),
          TextCellValue('https://example.com/b'),
        ],
      ]);
      final repository = ImportTestRepository();
      final vm = ExcelImportViewModel(
        repository,
        service: ExcelTestService(bytes),
      );
      await vm.choose();
      expect(vm.preview!.rows.first.warnings, isNotEmpty);
      expect(vm.preview!.rows.last.warnings.length, 2);
      await vm.confirm();
      expect(vm.saved, 1);
      expect(vm.failedRow, 3);
      expect(vm.error, contains('1/2'));
      await vm.confirm();
      expect(repository.stored.length, 1);
      vm.dispose();
    },
  );
}
