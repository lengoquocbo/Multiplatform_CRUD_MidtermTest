import 'dart:typed_data';
import '../services/image_service.dart';
import '../viewmodels/product_image_view_model.dart';
import '../models/image_value.dart';
import 'camera_view.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';
import '../viewmodels/product_form_view_model.dart';
import 'product_image.dart';

class ProductFormView extends StatefulWidget {
  const ProductFormView({
    super.key,
    required this.repository,
    this.product,
    this.imageService,
  });
  final ProductRepository repository;
  final Product? product;
  final ImageService? imageService;
  @override
  State<ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<ProductFormView> {
  late final model = ProductFormViewModel(widget.repository, widget.product);
  late final name = TextEditingController(text: widget.product?.name);
  late final price = TextEditingController(
    text: widget.product?.price.toString(),
  );
  late final quantity = TextEditingController(
    text: widget.product?.soluong.toString(),
  );
  late final image = TextEditingController(
    text: ImageValue.isHttps(widget.product?.image ?? '')
        ? widget.product!.image
        : '',
  );
  late final imageModel = ProductImageViewModel(
    widget.product?.image ?? '',
    service: widget.imageService,
  );
  @override
  void dispose() {
    name.dispose();
    price.dispose();
    quantity.dispose();
    image.dispose();
    imageModel.dispose();
    model.dispose();
    super.dispose();
  }

  Future<void> save() async {
    FocusScope.of(context).unfocus();
    final saved = await model.save(
      name.text,
      price.text,
      quantity.text,
      imageModel.value,
      imageError: imageModel.canSave
          ? null
          : imageModel.error ?? 'Chờ xem trước ảnh hợp lệ hoặc chọn ảnh.',
    );
    if (mounted && saved) Navigator.pop(context, true);
  }

  Widget field(
    String label,
    TextEditingController controller,
    String key, {
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: controller,
      enabled: !model.busy,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        errorText: model.errors[key],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([model, imageModel]),
    builder: (context, _) => PopScope(
      canPop: !model.busy && !imageModel.processing,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm',
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  field('Tên sản phẩm', name, 'name'),
                  field(
                    'Giá (đồng)',
                    price,
                    'price',
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  field(
                    'Số lượng',
                    quantity,
                    'soluong',
                    keyboard: TextInputType.number,
                  ),
                  TextField(
                    controller: image,
                    enabled: !model.busy && !imageModel.processing,
                    keyboardType: TextInputType.url,
                    onChanged: imageModel.changeUrl,
                    decoration: InputDecoration(
                      labelText: 'URL hình ảnh (HTTPS)',
                      errorText: imageModel.source == ImageSourceChoice.url
                          ? imageModel.error ?? model.errors['image']
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: model.busy || imageModel.processing
                            ? null
                            : imageModel.chooseFile,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Chọn file'),
                      ),
                      OutlinedButton.icon(
                        onPressed: model.busy || imageModel.processing
                            ? null
                            : () async {
                                final bytes = await Navigator.push<Uint8List>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CameraView(),
                                  ),
                                );
                                if (mounted) await imageModel.useCapture(bytes);
                              },
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Chụp ảnh'),
                      ),
                      if (image.text.isNotEmpty &&
                          imageModel.source != ImageSourceChoice.url)
                        TextButton(
                          onPressed: model.busy || imageModel.processing
                              ? null
                              : () => imageModel.changeUrl(image.text),
                          child: const Text('Dùng URL đã nhập'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nguồn đang dùng: ${switch (imageModel.source) {
                      ImageSourceChoice.url => 'URL',
                      ImageSourceChoice.file => 'File',
                      ImageSourceChoice.camera => 'Camera',
                    }}',
                  ),
                  if (imageModel.loading || imageModel.processing)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (imageModel.error != null &&
                      imageModel.source != ImageSourceChoice.url)
                    Text(
                      imageModel.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  Center(child: ProductImage(url: imageModel.value, size: 140)),
                  const SizedBox(height: 16),
                  if (model.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        model.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(
                        onPressed:
                            model.busy ||
                                imageModel.processing ||
                                imageModel.loading
                            ? null
                            : save,
                        child: Text(model.busy ? 'Đang lưu…' : 'Lưu'),
                      ),
                      OutlinedButton(
                        onPressed: model.busy || imageModel.processing
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
