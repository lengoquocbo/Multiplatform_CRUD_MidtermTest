import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/image_value.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.url, this.size = 56});
  final String url;
  final double size;
  Widget failure() => const Tooltip(
    message: 'Không tải được hình ảnh',
    child: Icon(Icons.broken_image_outlined, color: Colors.grey),
  );
  @override
  Widget build(BuildContext context) {
    Widget content;
    if (url.isEmpty) {
      content = const Icon(Icons.image_outlined, color: Colors.grey);
    } else if (url.startsWith('data:')) {
      if (!ImageValue.isData(url)) {
        content = failure();
      } else {
        content = Image.memory(
          base64Decode(url.substring(ImageValue.prefix.length)),
          key: ValueKey(url),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => failure(),
        );
      }
    } else {
      content = Image.network(
        url,
        key: ValueKey(url),
        fit: BoxFit.contain,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
        errorBuilder: (_, _, _) => failure(),
      );
    }
    return SizedBox(width: size, height: size, child: content);
  }
}
