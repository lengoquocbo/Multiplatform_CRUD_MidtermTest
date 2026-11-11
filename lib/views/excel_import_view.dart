import 'package:flutter/material.dart';
import '../repositories/product_repository.dart';
import '../viewmodels/excel_import_view_model.dart';

class ExcelImportView extends StatefulWidget {
  const ExcelImportView({super.key, required this.repository});
  final ProductRepository repository;
  @override
  State<ExcelImportView> createState() => _ExcelImportViewState();
}

class _ExcelImportViewState extends State<ExcelImportView> {
  late final model = ExcelImportViewModel(widget.repository);
  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  Future<void> confirm() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận nhập Excel'),
        content: Text(
          'Thêm ${model.preview!.rows.length} sản phẩm với ID mới? Hãy xem các cảnh báo trùng trước khi đồng ý. Dữ liệu cũ được giữ nguyên.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đồng ý nhập'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) await model.confirm();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => PopScope(
      canPop: !model.busy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nhập Excel'),
          automaticallyImplyLeading: !model.busy,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Worksheet đầu tiên, hàng 1: name, price, soluong, image. Chỉ nhận URL HTTPS trong cột image; không nhận công thức. Tối đa 1000 hàng.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: model.busy || model.attempted
                        ? null
                        : model.choose,
                    child: const Text('Chọn file XLSX'),
                  ),
                  FilledButton(
                    onPressed:
                        model.busy ||
                            model.attempted ||
                            model.preview?.valid != true
                        ? null
                        : confirm,
                    child: const Text('Xác nhận nhập'),
                  ),
                ],
              ),
              if (model.busy)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                ),
              if (model.attempted)
                Text(
                  'Đã lưu: ${model.saved}/${model.preview!.rows.length} dòng',
                ),
              if (model.finished)
                const Text(
                  'Nhập hoàn tất. Các dòng đã được Firestore xác nhận.',
                ),
              if (model.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    model.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    if (model.preview != null) ...[
                      Text(
                        '${model.preview!.rows.length} hàng dữ liệu, ${model.preview!.errors.length} lỗi.',
                      ),
                      ...model.preview!.errors.map(
                        (error) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            error,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                      const Divider(),
                      ...model.preview!.rows.map(
                        (row) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hàng ${row.number}: ${row.cells[0]}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Giá: ${row.cells[1]} — Số lượng: ${row.cells[2]}',
                              ),
                              Text(
                                row.cells[3],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              ...row.warnings.map(
                                (warning) => Text(
                                  warning,
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
