import 'dart:math' as math;
import 'package:image/image.dart' as img;
import '../models/image_value.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import '../models/product.dart';

Uint8List buildProductsXlsx(List<Product> products) {
  const mainNamespace =
      'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
  String escape(String value) => XmlText(value).toXmlString();
  String textCell(String address, String value, {bool header = false}) {
    if (value.length > 32767) {
      throw const FormatException(
        'Dữ liệu chữ vượt giới hạn 32.767 ký tự mỗi ô Excel. Chưa xuất hoặc cắt bớt dữ liệu.',
      );
    }
    if (RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]').hasMatch(value)) {
      throw const FormatException(
        'Dữ liệu chứa ký tự điều khiển không được Excel hỗ trợ.',
      );
    }
    return '<c r="$address" t="inlineStr"${header ? ' s="1"' : ''}><is><t xml:space="preserve">${escape(value)}</t></is></c>';
  }

  String numberCell(String address, num value) {
    final raw = value.toString();
    final significant = raw
        .split(RegExp('[eE]'))
        .first
        .replaceAll(RegExp('[^0-9]'), '')
        .replaceFirst(RegExp('^0+'), '');
    if (significant.length > 15) return textCell(address, raw);
    return '<c r="$address"><v>$raw</v></c>';
  }

  final media = <String, Uint8List>{};
  final anchors = <String>[];
  final rows = <String>[
    '<row r="1">${['name', 'price', 'soluong', 'image'].asMap().entries.map((entry) => textCell('${String.fromCharCode(65 + entry.key)}1', entry.value, header: true)).join()}</row>',
  ];
  for (var index = 0; index < products.length; index++) {
    final p = products[index];
    final row = index + 2;
    var imageText = p.image;
    var rowHeight = '';
    if (p.image.startsWith('data:')) {
      if (!ImageValue.isData(p.image)) {
        throw const FormatException('Ảnh JPEG Data URI không hợp lệ.');
      }
      final bytes = base64Decode(p.image.substring(ImageValue.prefix.length));
      final info = img.JpegDecoder().startDecode(bytes);
      if (info == null || info.width <= 0 || info.height <= 0) {
        throw const FormatException(
          'Không đọc được kích thước ảnh JPEG để xuất Excel.',
        );
      }
      final scale = math.min(160 / info.width, 72 / info.height);
      final cx = (info.width * scale * 9525).round();
      final cy = (info.height * scale * 9525).round();
      final id = media.length + 1;
      media['image$id.jpg'] = bytes;
      anchors.add(
        '<xdr:oneCellAnchor><xdr:from><xdr:col>3</xdr:col><xdr:colOff>38100</xdr:colOff><xdr:row>${row - 1}</xdr:row><xdr:rowOff>38100</xdr:rowOff></xdr:from><xdr:ext cx="$cx" cy="$cy"/><xdr:pic><xdr:nvPicPr><xdr:cNvPr id="$id" name="Product image $id"/><xdr:cNvPicPr><a:picLocks noChangeAspect="1"/></xdr:cNvPicPr></xdr:nvPicPr><xdr:blipFill><a:blip r:embed="rId$id"/><a:stretch><a:fillRect/></a:stretch></xdr:blipFill><xdr:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$cx" cy="$cy"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></xdr:spPr></xdr:pic><xdr:clientData/></xdr:oneCellAnchor>',
      );
      imageText = '';
      rowHeight = ' ht="60" customHeight="1"';
    }
    rows.add(
      '<row r="$row"$rowHeight>${textCell('A$row', p.name)}${numberCell('B$row', p.price)}${numberCell('C$row', p.soluong)}${textCell('D$row', imageText)}</row>',
    );
  }
  final files = <String, String>{
    '[Content_Types].xml':
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Default Extension="jpg" ContentType="image/jpeg"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>${media.isNotEmpty ? '<Override PartName="/xl/drawings/drawing1.xml" ContentType="application/vnd.openxmlformats-officedocument.drawing+xml"/>' : ''}</Types>',
    '_rels/.rels':
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>',
    'xl/workbook.xml':
        '<workbook xmlns="$mainNamespace" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><bookViews><workbookView/></bookViews><sheets><sheet name="Products" sheetId="1" r:id="rId1"/></sheets></workbook>',
    'xl/_rels/workbook.xml.rels':
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>',
    'xl/styles.xml':
        '<styleSheet xmlns="$mainNamespace"><fonts count="2"><font><sz val="11"/><name val="Arial"/></font><font><b/><sz val="11"/><name val="Arial"/></font></fonts><fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills><borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/></cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>',
    'xl/worksheets/sheet1.xml':
        '<worksheet xmlns="$mainNamespace" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews><cols><col min="1" max="1" width="28" customWidth="1"/><col min="2" max="3" width="18" customWidth="1"/><col min="4" max="4" width="65" customWidth="1"/></cols><sheetData>${rows.join()}</sheetData><autoFilter ref="A1:D${products.length + 1}"/>${media.isNotEmpty ? '<drawing r:id="imageDrawing"/>' : ''}</worksheet>',
  };
  if (media.isNotEmpty) {
    files['xl/worksheets/_rels/sheet1.xml.rels'] =
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="imageDrawing" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/drawing" Target="../drawings/drawing1.xml"/></Relationships>';
    files['xl/drawings/drawing1.xml'] =
        '<xdr:wsDr xmlns:xdr="http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">${anchors.join()}</xdr:wsDr>';
    files['xl/drawings/_rels/drawing1.xml.rels'] =
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">${List.generate(media.length, (i) => '<Relationship Id="rId${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/image${i + 1}.jpg"/>').join()}</Relationships>';
  }
  final archive = Archive();
  for (final entry in media.entries) {
    archive.addFile(
      ArchiveFile('xl/media/${entry.key}', entry.value.length, entry.value),
    );
  }
  for (final entry in files.entries) {
    final bytes = utf8.encode(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>${entry.value}',
    );
    archive.addFile(ArchiveFile(entry.key, bytes.length, bytes));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}
