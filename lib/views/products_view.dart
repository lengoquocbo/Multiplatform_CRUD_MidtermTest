import 'excel_import_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';
import '../services/error_message.dart';
import '../services/excel_file_service.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/products_view_model.dart';
import 'product_form_view.dart';
import 'product_image.dart';

class ProductsView extends StatefulWidget {
  const ProductsView({super.key, required this.repository, required this.auth});
  final ProductRepository repository;
  final AuthViewModel auth;
  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  late final model = ProductsViewModel(widget.repository);
  final files = ExcelFileService();
  final currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );
  bool fileBusy = false;
  bool get busy => model.busy || fileBusy;
  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  void message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(value)));
    }
  }

  Future<void> form([Product? product]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProductFormView(repository: widget.repository, product: product),
      ),
    );
    if (result == true) message('Đã lưu sản phẩm trên Firestore.');
  }

  Future<void> remove(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Xóa sản phẩm'),
        content: Text('Bạn muốn xóa “${product.name}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final ok = await model.delete(product.id);
      message(
        ok
            ? 'Đã xóa sản phẩm trên Firestore.'
            : model.actionError ?? 'Chưa xóa được.',
      );
    }
  }

  Future<void> export() async {
    if (busy) return;
    setState(() => fileBusy = true);
    try {
      final result = await model.exportExcel();
      if (result == null) {
        message(model.actionError ?? 'Không xuất được dữ liệu.');
        return;
      }
      await files.save(result.bytes);
      message(
        'Đã tạo Excel từ dữ liệu trên máy chủ. ${result.hasDataImages ? 'File có ảnh nhúng; chức năng nhập Excel hiện chỉ nhận URL HTTPS.' : 'Kiểm tra file tải về hoặc thư mục ứng dụng.'}',
      );
    } catch (error) {
      message(errorMessage(error));
    } finally {
      if (mounted) setState(() => fileBusy = false);
    }
  }

  Future<void> import() async {
    if (busy) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ExcelImportView(repository: widget.repository),
      ),
    );
  }

  Widget actions(Product product) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'Sửa sản phẩm',
        onPressed: busy ? null : () => form(product),
        icon: const Icon(Icons.edit_outlined),
      ),
      IconButton(
        tooltip: 'Xóa sản phẩm',
        onPressed: busy ? null : () => remove(product),
        icon: const Icon(Icons.delete_outline),
        color: Colors.red,
      ),
    ],
  );
  Widget data(bool desktop) {
    if (model.loading) return const Center(child: CircularProgressIndicator());
    if (model.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              model.error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: model.retry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (model.products.isEmpty) {
      return Center(
        child: Text(
          model.empty
              ? (model.fromCache
                    ? 'Đang chờ dữ liệu từ máy chủ…'
                    : 'Chưa có sản phẩm.')
              : 'Không có kết quả tìm kiếm.',
        ),
      );
    }
    if (!desktop) {
      return ListView.separated(
        itemCount: model.products.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final product = model.products[index];
          return Padding(
            key: ValueKey(product.id),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                ProductImage(url: product.image),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(
                        width: 150,
                        child: Text(
                          currency.format(product.price),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Số lượng: ${product.soluong}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                actions(product),
              ],
            ),
          );
        },
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: SizedBox(
          width: constraints.maxWidth,
          child: DataTable(
            columnSpacing: 20,
            dataRowMinHeight: 76,
            dataRowMaxHeight: 88,
            columns: const [
              DataColumn(label: Text('Hình ảnh')),
              DataColumn(label: Text('Tên sản phẩm')),
              DataColumn(label: Text('Giá'), numeric: true),
              DataColumn(label: Text('Số lượng'), numeric: true),
              DataColumn(label: Text('Thao tác')),
            ],
            rows: model.products
                .map(
                  (product) => DataRow(
                    key: ValueKey(product.id),
                    cells: [
                      DataCell(ProductImage(url: product.image)),
                      DataCell(
                        SizedBox(
                          width: (constraints.maxWidth * .20).clamp(100, 340),
                          child: Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(
                            currency.format(product.price),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${product.soluong}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(actions(product)),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sản phẩm'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: busy || widget.auth.busy ? null : widget.auth.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: busy ? null : () => form(),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm sản phẩm'),
                ),
                OutlinedButton(
                  onPressed: busy ? null : export,
                  child: const Text('Xuất Excel'),
                ),
                OutlinedButton(
                  onPressed: busy ? null : import,
                  child: const Text('Nhập Excel'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: model.search,
              decoration: const InputDecoration(
                labelText: 'Tìm kiếm theo tên',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            if (widget.auth.error != null)
              Text(
                widget.auth.error!,
                style: const TextStyle(color: Colors.red),
              ),
            if (busy) const LinearProgressIndicator(),
            if (model.fromCache && !model.loading && model.error == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Đang chờ máy chủ. Dữ liệu tạm thời chưa được xác nhận.',
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) =>
                    data(constraints.maxWidth >= 900),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
