import 'package:gk_dnt_le_ngo_quoc_bo/services/image_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gk_dnt_le_ngo_quoc_bo/models/product.dart';
import 'package:gk_dnt_le_ngo_quoc_bo/repositories/product_repository.dart';
import 'package:gk_dnt_le_ngo_quoc_bo/services/product_service.dart';
import 'package:gk_dnt_le_ngo_quoc_bo/viewmodels/auth_view_model.dart';
import 'package:gk_dnt_le_ngo_quoc_bo/views/products_view.dart';
import 'package:gk_dnt_le_ngo_quoc_bo/views/product_form_view.dart';

class LayoutImageService extends ImageService {
  @override
  Future<void> validateUrl(String url) async {}
}

class LayoutRepository extends Fake implements ProductRepository {
  @override
  String newId() => 'layout-test';
  @override
  Stream<ProductSnapshot> watch() => Stream.value(
    ProductSnapshot([
      Product(
        id: 'layout',
        name: List.filled(40, 'Tên dài').join(' '),
        price: 9999999999999,
        soluong: 9007199254740991,
        image: '',
      ),
    ], false),
  );
  @override
  Future<void> save(Product product, {required bool creating}) async {
    throw StateError('Lỗi lưu kiểm thử');
  }
}

class LayoutAuth extends Fake implements AuthViewModel {
  @override
  bool get busy => false;
  @override
  String? get error => null;
}

void main() {
  for (final width in [320.0, 1024.0]) {
    testWidgets('Danh sách ở chiều rộng $width không tràn khi tên dài', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsView(
            repository: LayoutRepository(),
            auth: LayoutAuth(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Quản lý sản phẩm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Form nhỏ hiển thị lỗi và giữ dữ liệu khi lưu thất bại', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: ProductFormView(
          repository: LayoutRepository(),
          imageService: LayoutImageService(),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Lưu'));
    await tester.tap(find.text('Lưu'));
    await tester.pump();
    expect(find.text('Nhập tên sản phẩm.'), findsOneWidget);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Bút');
    await tester.enterText(fields.at(1), '1000');
    await tester.enterText(fields.at(2), '2');
    await tester.enterText(fields.at(3), 'https://example.com/a.png');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    await tester.ensureVisible(find.text('Lưu'));
    await tester.ensureVisible(find.text('Lưu'));
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Lỗi lưu kiểm thử'), findsOneWidget);
    expect(find.text('Bút'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
