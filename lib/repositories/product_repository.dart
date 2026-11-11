import 'dart:convert';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductRepository {
  ProductRepository(this._service);
  final ProductService _service;
  Stream<ProductSnapshot> watch() => _service.watch();
  Future<List<Product>> fetchServer() => _service.fetchServer();
  String newId() => _service.newId();
  Future<void> save(Product product, {required bool creating}) =>
      _service.save(product, creating: creating);
  Future<void> delete(String id) => _service.delete(id);
  Future<String> exportJson() async {
    final products = await _service.fetchServer();
    return const JsonEncoder.withIndent(
      '  ',
    ).convert({for (final product in products) product.id: product.toMap()});
  }

  static List<Product> parseJson(String text) {
    final Object? decoded = jsonDecode(text);
    if (decoded is! Map<String, Object?> ||
        decoded.isEmpty ||
        decoded.length > 100) {
      throw const FormatException(
        'JSON phải chứa từ 1 đến 100 sản phẩm, với ID làm khóa.',
      );
    }
    return decoded.entries.map((entry) {
      final id = entry.key;
      if (id.isEmpty ||
          id.contains('/') ||
          id == '.' ||
          id == '..' ||
          RegExp(r'^__.*__$').hasMatch(id) ||
          utf8.encode(id).length > 1500) {
        throw const FormatException('Document ID trong JSON không hợp lệ.');
      }
      if (entry.value is! Map<String, Object?>) {
        throw FormatException('Sản phẩm $id không phải đối tượng JSON.');
      }
      return Product.fromMap(id, entry.value! as Map<String, Object?>);
    }).toList();
  }

  Future<void> importProducts(List<Product> products) =>
      _service.importProducts(products);
}
