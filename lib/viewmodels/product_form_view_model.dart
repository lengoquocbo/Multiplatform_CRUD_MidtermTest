import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';
import '../services/error_message.dart';

class ProductFormViewModel extends ChangeNotifier {
  ProductFormViewModel(this.repository, this.product)
    : id = product?.id ?? repository.newId();
  final ProductRepository repository;
  final Product? product;
  final String id;
  bool busy = false;
  String? error;
  Map<String, String> errors = {};
  static Map<String, String> validate(
    String name,
    String price,
    String quantity,
    String image,
  ) {
    final errors = <String, String>{};
    if (name.trim().isEmpty) errors['name'] = 'Nhập tên sản phẩm.';
    final p = num.tryParse(price.trim());
    if (p == null || !p.isFinite || p < 0) {
      errors['price'] =
          'Nhập số hữu hạn không âm; dùng dấu chấm cho phần thập phân.';
    }
    final q = int.tryParse(quantity.trim());
    if (q == null || q < 0 || q > 9007199254740991) {
      errors['soluong'] = 'Nhập số nguyên từ 0 đến 9007199254740991.';
    }
    if (!Product.validImage(image.trim())) {
      errors['image'] = 'Chọn ảnh JPEG đã xử lý hoặc URL HTTPS hợp lệ.';
    }
    return errors;
  }

  Future<bool> save(
    String name,
    String price,
    String quantity,
    String image, {
    String? imageError,
  }) async {
    if (busy) return false;
    errors = validate(name, price, quantity, image);
    if (imageError != null) errors['image'] = imageError;
    error = null;
    if (errors.isNotEmpty) {
      notifyListeners();
      return false;
    }
    busy = true;
    notifyListeners();
    try {
      await repository.save(
        Product(
          id: id,
          name: name.trim(),
          price: num.parse(price.trim()),
          soluong: int.parse(quantity.trim()),
          image: image.trim(),
        ),
        creating: product == null,
      );
      return true;
    } catch (value) {
      error = errorMessage(value);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
