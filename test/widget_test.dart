import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gk_dnt_le_ngo_quoc_bo/views/product_image.dart';

void main() {
  testWidgets('Ảnh rỗng có hình thay thế trên màn hình nhỏ', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ProductImage(url: '')),
      ),
    );
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
