import 'image_value.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.soluong,
    required this.image,
  });
  final String id;
  final String name;
  final num price;
  final int soluong;
  final String image;
  Map<String, Object> toMap() => {
    'name': name,
    'price': price,
    'soluong': soluong,
    'image': image,
  };
  static bool validImage(String value) => ImageValue.isValid(value);

  factory Product.fromMap(String id, Map<String, Object?> data) {
    if (data.length != 4 ||
        !data.keys.toSet().containsAll({'name', 'price', 'soluong', 'image'})) {
      throw FormatException('Sản phẩm $id phải có đúng bốn trường.');
    }
    final name = data['name'];
    final price = data['price'];
    final quantity = data['soluong'];
    final image = data['image'];
    if (name is! String ||
        name.trim().isEmpty ||
        name != name.trim() ||
        price is! num ||
        !price.isFinite ||
        price < 0 ||
        quantity is! int ||
        quantity < 0 ||
        quantity > 9007199254740991 ||
        image is! String ||
        !validImage(image)) {
      throw FormatException('Dữ liệu sản phẩm $id không hợp lệ.');
    }
    return Product(
      id: id,
      name: name,
      price: price,
      soluong: quantity,
      image: image,
    );
  }
}
