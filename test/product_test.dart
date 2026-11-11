import 'package:flutter_test/flutter_test.dart';
import 'package:gk_dnt_le_ngo_quoc_bo/models/product.dart';
import 'package:gk_dnt_le_ngo_quoc_bo/repositories/product_repository.dart';
import 'package:gk_dnt_le_ngo_quoc_bo/viewmodels/product_form_view_model.dart';

void main() {
  test('Lưu đúng bốn trường, ID chỉ nằm trong model', () {
    const p = Product(
      id: 'abc',
      name: 'Bút',
      price: 1000,
      soluong: 2,
      image: 'https://example.com/a.png',
    );
    expect(p.toMap().keys.toSet(), {'name', 'price', 'soluong', 'image'});
    expect(Product.fromMap('abc', p.toMap()).id, 'abc');
  });
  test('Chặn tên rỗng, số âm, NaN, vô cực, số lượng lẻ và URL HTTP', () {
    for (final price in ['-1', 'NaN', 'Infinity', 'abc']) {
      expect(
        ProductFormViewModel.validate(
          'Bút',
          price,
          '1',
          'https://example.com/a.png',
        ),
        contains('price'),
      );
    }
    expect(
      ProductFormViewModel.validate('  ', '1', '1.5', 'http://example.com'),
      containsPair('name', 'Nhập tên sản phẩm.'),
    );
    expect(
      ProductFormViewModel.validate('Bút', '1', '-1', 'https://example.com'),
      contains('soluong'),
    );
    expect(
      ProductFormViewModel.validate('Bút', '1', '1', 'https://'),
      contains('image'),
    );
    expect(
      ProductFormViewModel.validate(
        ' Bút ',
        '0',
        '0',
        'https://example.com/a.png',
      ),
      isEmpty,
    );
  });
  test('JSON từ chối trường thừa, sai kiểu và ID sai', () {
    for (final text in [
      '[]',
      '{}',
      '{"a":{"name":"Bút"}}',
      '{"a/b":{}}',
      '{"a":{"name":"Bút","price":1,"soluong":1.5,"image":"https://example.com"}}',
    ]) {
      expect(() => ProductRepository.parseJson(text), throwsFormatException);
    }
  });
  test('JSON nhập lại giữ ID và đúng kiểu', () {
    final list = ProductRepository.parseJson(
      '{"but":{"name":"Bút","price":1000.5,"soluong":2,"image":"https://example.com/a.png"}}',
    );
    expect(list.single.id, 'but');
    expect(list.single.soluong, 2);
  });
}
