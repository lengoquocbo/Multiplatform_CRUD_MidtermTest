import '../services/excel_export_service.dart';
import '../models/image_value.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';
import '../services/error_message.dart';
import '../services/product_service.dart';

class ProductsViewModel extends ChangeNotifier {
  ProductsViewModel(this.repository) {
    retry();
  }
  final ProductRepository repository;
  StreamSubscription<ProductSnapshot>? _subscription;
  List<Product> _products = [];
  bool loading = true;
  bool busy = false;
  bool fromCache = true;
  bool _disposed = false;
  String query = '';
  String? error;
  String? actionError;
  bool get empty => _products.isEmpty;
  List<Product> get products =>
      _products
          .where(
            (p) => p.name.toLowerCase().contains(query.toLowerCase().trim()),
          )
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  void search(String value) {
    query = value;
    notifyListeners();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> retry() async {
    await _subscription?.cancel();
    if (_disposed) return;
    loading = true;
    error = null;
    _notify();
    _subscription = repository.watch().listen(
      (snapshot) {
        _products = snapshot.products;
        fromCache = snapshot.fromCache;
        loading = false;
        error = null;
        _notify();
      },
      onError: (Object value) {
        error = errorMessage(value);
        loading = false;
        _notify();
      },
    );
  }

  Future<T?> _perform<T>(Future<T> Function() action) async {
    if (busy) return null;
    busy = true;
    actionError = null;
    _notify();
    try {
      return await action();
    } catch (value) {
      actionError = errorMessage(value);
      return null;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> delete(String id) async =>
      await _perform(() async {
        await repository.delete(id);
        return true;
      }) ??
      false;
  Future<({Uint8List bytes, bool hasDataImages})?> exportExcel() =>
      _perform(() async {
        final values = await repository.fetchServer();
        final bytes = await compute(buildProductsXlsx, values);
        return (
          bytes: bytes,
          hasDataImages: values.any((p) => ImageValue.isData(p.image)),
        );
      });
  List<Product> parseJson(String text) => ProductRepository.parseJson(text);
  Future<bool> importProducts(List<Product> values) async =>
      await _perform(() async {
        await repository.importProducts(values);
        return true;
      }) ??
      false;
  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
