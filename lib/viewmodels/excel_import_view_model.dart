import 'package:flutter/foundation.dart';
import '../models/excel_import.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';
import '../services/error_message.dart';
import '../services/excel_service.dart';

class ExcelImportViewModel extends ChangeNotifier {
  ExcelImportViewModel(this.repository, {ExcelService? service})
    : service = service ?? ExcelService();
  final ProductRepository repository;
  final ExcelService service;
  ExcelPreview? preview;
  String? error;
  bool busy = false;
  bool attempted = false;
  bool finished = false;
  int saved = 0;
  int? failedRow;
  bool _disposed = false;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> choose() async {
    if (busy || attempted) return;
    busy = true;
    error = null;
    _notify();
    try {
      final bytes = await service.pick();
      if (bytes == null || _disposed) return;
      final result = await service.parse(bytes);
      if (_disposed) return;
      preview = result;
      if (result.valid) {
        final existing = await repository.fetchServer();
        final names = existing.map((p) => p.name.trim().toLowerCase()).toSet();
        final seen = <String, int>{};
        for (final row in result.rows) {
          final key = row.product!.name.toLowerCase();
          if (names.contains(key)) {
            row.warnings.add('Tên trùng sản phẩm đang có trên Firestore.');
          }
          if (seen.containsKey(key)) {
            row.warnings.add('Tên trùng hàng ${seen[key]} trong file.');
          }
          seen.putIfAbsent(key, () => row.number);
        }
      }
    } catch (e) {
      preview = null;
      error = errorMessage(e);
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> confirm() async {
    if (busy || attempted || preview?.valid != true) return;
    busy = true;
    attempted = true;
    error = null;
    _notify();
    try {
      for (final row in preview!.rows) {
        failedRow = row.number;
        final p = row.product!;
        final product = Product(
          id: repository.newId(),
          name: p.name,
          price: p.price,
          soluong: p.soluong,
          image: p.image,
        );
        await repository.save(product, creating: true);
        saved++;
        _notify();
      }
      failedRow = null;
      finished = true;
    } catch (e) {
      error =
          'Đã xác nhận lưu $saved/${preview!.rows.length} dòng. Dừng tại hàng $failedRow: ${errorMessage(e)} Nếu lỗi kết nối, hàng này có thể chưa xác định kết quả; kiểm tra Firestore trước khi tạo file mới chỉ chứa các hàng chưa lưu. Ứng dụng không tự nhập lại.';
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
