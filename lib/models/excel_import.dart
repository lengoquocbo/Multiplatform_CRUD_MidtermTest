import 'product.dart';

class ExcelRow {
  ExcelRow(this.number, this.cells, {this.product});
  final int number;
  final List<String> cells;
  final Product? product;
  final List<String> warnings = [];
}

class ExcelPreview {
  ExcelPreview(this.rows, this.errors);
  final List<ExcelRow> rows;
  final List<String> errors;
  bool get valid => errors.isEmpty && rows.isNotEmpty;
}
