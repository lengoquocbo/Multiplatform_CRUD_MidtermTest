import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import '../models/excel_import.dart';
import '../models/image_value.dart';
import '../models/product.dart';

class _Cell {
  const _Cell(this.text, this.type, this.formula);
  final String text;
  final String type;
  final bool formula;
}

ExcelPreview parseExcel(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
    throw const FormatException('File XLSX phải từ 1 byte đến 10 MB.');
  }
  final archive = ZipDecoder().decodeBytes(bytes);
  if (archive.files.fold<int>(0, (total, file) => total + file.size) >
      25 * 1024 * 1024) {
    throw const FormatException('Nội dung giải nén vượt 25 MB.');
  }
  String readXml(String name) {
    final file = archive.findFile(name);
    if (file == null) {
      throw const FormatException('Cấu trúc XLSX không hợp lệ.');
    }
    return utf8.decode(file.content as List<int>);
  }

  Iterable<XmlElement> elements(XmlNode node, String name) => node.descendants
      .whereType<XmlElement>()
      .where((e) => e.name.local == name);
  String texts(XmlNode node) =>
      elements(node, 't').map((e) => e.innerText).join();
  final workbookXml = XmlDocument.parse(readXml('xl/workbook.xml'));
  final firstSheet = elements(workbookXml, 'sheet').firstOrNull;
  if (firstSheet == null) throw const FormatException('Không có worksheet.');
  final relationId = firstSheet.attributes
      .where((a) => a.name.local == 'id')
      .first
      .value;
  final relations = XmlDocument.parse(readXml('xl/_rels/workbook.xml.rels'));
  final relation = elements(
    relations,
    'Relationship',
  ).firstWhere((e) => e.getAttribute('Id') == relationId);
  final target = relation.getAttribute('Target')!;
  final sheetPath = Uri(
    path: 'xl/workbook.xml',
  ).resolve(target).path.replaceFirst(RegExp(r'^/'), '');
  final sheetXml = XmlDocument.parse(readXml(sheetPath));
  final shared = <String>[];
  if (archive.findFile('xl/sharedStrings.xml') != null) {
    shared.addAll(
      elements(
        XmlDocument.parse(readXml('xl/sharedStrings.xml')),
        'si',
      ).map(texts),
    );
  }
  final errors = <String>[];
  var hasEmbeddedPicture = elements(sheetXml, 'picture').isNotEmpty;
  final sheetRelationsPath = Uri(
    path: sheetPath,
  ).resolve('_rels/${sheetPath.split('/').last}.rels').path;
  if (archive.findFile(sheetRelationsPath) != null) {
    final sheetRelations = XmlDocument.parse(readXml(sheetRelationsPath));
    for (final drawing in elements(sheetXml, 'drawing')) {
      final id = drawing.attributes
          .where((a) => a.name.local == 'id')
          .firstOrNull
          ?.value;
      final link = elements(
        sheetRelations,
        'Relationship',
      ).where((e) => e.getAttribute('Id') == id).firstOrNull;
      final target = link?.getAttribute('Target');
      if (target != null && link?.getAttribute('TargetMode') != 'External') {
        final path = Uri(
          path: sheetPath,
        ).resolve(target).path.replaceFirst(RegExp(r'^/'), '');
        if (archive.findFile(path) != null &&
            elements(XmlDocument.parse(readXml(path)), 'pic').isNotEmpty) {
          hasEmbeddedPicture = true;
        }
      }
    }
  }
  if (hasEmbeddedPicture) {
    errors.add(
      'Worksheet có ảnh nhúng. Hãy xóa ảnh và dùng URL HTTPS trong cột image.',
    );
  }
  final grid = <int, Map<int, _Cell>>{};
  for (final cell in elements(sheetXml, 'c')) {
    final coordinate = cell.getAttribute('r') ?? '';
    final match = RegExp(r'^([A-Z]+)([1-9][0-9]*)$').firstMatch(coordinate);
    if (match == null) {
      throw const FormatException('Tọa độ ô XLSX không hợp lệ.');
    }
    final row = int.parse(match.group(2)!);
    var col = 0;
    for (final letter in match.group(1)!.codeUnits) {
      col = col * 26 + letter - 64;
    }
    if (row > 1048576 || col > 16384) {
      throw const FormatException('Tọa độ vượt giới hạn worksheet XLSX.');
    }
    final type = cell.getAttribute('t') ?? 'n';
    var raw = elements(cell, 'v').firstOrNull?.innerText ?? '';
    if (type == 'inlineStr') raw = texts(cell);
    if (type == 's') {
      final index = int.tryParse(raw);
      if (index == null || index < 0 || index >= shared.length) {
        throw const FormatException('Chỉ số chuỗi XLSX không hợp lệ.');
      }
      raw = shared[index];
    }
    final formula = cell.childElements.any((e) => e.name.local == 'f');
    if (raw.trim().isEmpty && !formula) continue;
    if (col > 100) {
      throw const FormatException('Có dữ liệu ngoài giới hạn 100 cột.');
    }
    if (formula) {
      errors.add('Ô $coordinate: không hỗ trợ công thức, hãy dán giá trị.');
    }
    final cells = grid.putIfAbsent(row, () => {});
    if (cells.containsKey(col)) {
      throw FormatException('Ô $coordinate bị lặp trong XLSX.');
    }
    cells[col] = _Cell(raw.trim(), type, formula);
  }
  final headers = grid[1] ?? {};
  const required = ['name', 'price', 'soluong', 'image'];
  final firstFour = [for (var c = 1; c <= 4; c++) headers[c]?.text ?? ''];
  if (headers.values.where((h) => h.text.isNotEmpty).length != 4 ||
      firstFour.toSet().length != 4 ||
      !firstFour.toSet().containsAll(required)) {
    errors.add(
      'Hàng 1 (A–D) phải gồm đúng bốn tiêu đề name, price, soluong, image; có thể đổi thứ tự cột.',
    );
    return ExcelPreview([], errors);
  }
  final indexes = {for (final key in required) key: firstFour.indexOf(key) + 1};
  final parsed = <ExcelRow>[];
  final rowNumbers = grid.keys.where((r) => r > 1).toList()..sort();
  if (rowNumbers.length > 1000) {
    throw const FormatException('Tối đa 1000 hàng dữ liệu không trống.');
  }
  for (final r in rowNumbers) {
    final cells = grid[r]!;
    if (cells.values.every((cell) => cell.text.isEmpty && !cell.formula)) {
      continue;
    }
    final rowErrors = <String>[];
    final values = <String, Object?>{};
    for (final key in required) {
      final index = indexes[key]!;
      final cell = cells[index];
      final raw = cell?.text ?? '';
      final at = 'Hàng $r, cột ${String.fromCharCode(64 + index)} ($key)';
      if (cell?.formula == true) {
        rowErrors.add('$at: không hỗ trợ công thức.');
        continue;
      }
      if (key == 'name') {
        if (raw.isEmpty || cell?.type == 'e') {
          rowErrors.add('$at: tên không được trống hoặc chứa lỗi Excel.');
        }
        values[key] = raw;
      } else if (key == 'image') {
        if (!ImageValue.isHttps(raw)) {
          rowErrors.add(
            '$at: chỉ nhận URL HTTPS tối đa 2048 ký tự, không nhận Base64/ảnh nhúng.',
          );
        }
        values[key] = raw;
      } else {
        final number = ['b', 'e', 'd'].contains(cell?.type)
            ? null
            : num.tryParse(raw);
        if (number == null ||
            !number.isFinite ||
            number < 0 ||
            (key == 'soluong' &&
                (number != number.truncateToDouble() ||
                    number > 9007199254740991))) {
          rowErrors.add(
            '$at: ${key == 'soluong' ? 'cần số nguyên' : 'cần số hữu hạn'} không âm.',
          );
        } else {
          values[key] = key == 'soluong' ? number.toInt() : number;
        }
      }
    }
    for (final entry in cells.entries.where((e) => e.key > 4)) {
      if (entry.value.text.isNotEmpty || entry.value.formula) {
        rowErrors.add('Hàng $r, cột ${entry.key}: dữ liệu nằm ngoài bốn cột.');
      }
    }
    final previewCells = required
        .map((key) => cells[indexes[key]]?.text ?? '')
        .toList();
    Product? product;
    if (rowErrors.isEmpty) product = Product.fromMap('', values);
    parsed.add(ExcelRow(r, previewCells, product: product));
    errors.addAll(rowErrors);
  }
  if (parsed.isEmpty) errors.add('Không có hàng dữ liệu để nhập.');
  return ExcelPreview(parsed, errors);
}
