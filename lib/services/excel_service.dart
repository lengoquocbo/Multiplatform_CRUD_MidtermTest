export 'excel_parser.dart' show parseExcel;
import 'excel_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/excel_import.dart';

class ExcelService {
  Future<Uint8List?> pick() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null) return null;
    final file = result.files.single;
    if (file.extension?.toLowerCase() != 'xlsx' ||
        file.size > 10 * 1024 * 1024 ||
        file.bytes == null) {
      throw const FormatException('Chọn file .xlsx tối đa 10 MB.');
    }
    return file.bytes!;
  }

  Future<ExcelPreview> parse(Uint8List bytes) async {
    try {
      return await compute(parseExcel, bytes);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(
        'Không đọc được XLSX. Kiểm tra file đúng định dạng, không mã hóa và không bị hỏng.',
      );
    }
  }
}
