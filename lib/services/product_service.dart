import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductSnapshot {
  const ProductSnapshot(this.products, this.fromCache);
  final List<Product> products;
  final bool fromCache;
}

class ProductService {
  ProductService(this._db);
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('products');
  String newId() => _collection.doc().id;
  ProductSnapshot _decode(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      ProductSnapshot(
        snapshot.docs
            .map((doc) => Product.fromMap(doc.id, doc.data()))
            .toList(),
        snapshot.metadata.isFromCache,
      );
  Stream<ProductSnapshot> watch() =>
      _collection.snapshots(includeMetadataChanges: true).map(_decode);
  Future<List<Product>> fetchServer() async => _decode(
    await _collection.get(const GetOptions(source: Source.server)),
  ).products;
  Future<void> save(Product product, {required bool creating}) async {
    final reference = _collection.doc(product.id);
    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (creating && existing.exists) {
        final stored = Product.fromMap(existing.id, existing.data()!);
        if (stored.name == product.name &&
            stored.price == product.price &&
            stored.soluong == product.soluong &&
            stored.image == product.image) {
          return;
        }
        throw StateError('Mã sản phẩm đã tồn tại. Đóng form và thử lại.');
      }
      if (!creating && !existing.exists) {
        throw StateError('Sản phẩm đã bị xóa. Hãy tải lại danh sách.');
      }
      transaction.set(reference, product.toMap());
    });
  }

  Future<void> delete(String id) async {
    await _db.runTransaction((transaction) async {
      final reference = _collection.doc(id);
      final existing = await transaction.get(reference);
      if (!existing.exists) {
        throw StateError('Sản phẩm không còn tồn tại. Tải lại danh sách.');
      }
      transaction.delete(reference);
    });
  }

  Future<void> importProducts(List<Product> products) async {
    await _db.runTransaction((transaction) async {
      for (final product in products) {
        final existing = await transaction.get(_collection.doc(product.id));
        if (existing.exists) {
          throw StateError(
            'ID ${product.id} đã tồn tại. Chưa nhập dữ liệu nào.',
          );
        }
      }
      for (final product in products) {
        transaction.set(_collection.doc(product.id), product.toMap());
      }
    });
  }
}
