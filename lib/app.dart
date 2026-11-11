import 'package:flutter/material.dart';
import 'repositories/product_repository.dart';
import 'viewmodels/auth_view_model.dart';
import 'views/login_view.dart';
import 'views/products_view.dart';

class ProductApp extends StatefulWidget {
  const ProductApp({super.key, required this.auth, required this.repository});
  final AuthViewModel auth;
  final ProductRepository repository;
  @override
  State<ProductApp> createState() => _ProductAppState();
}

class _ProductAppState extends State<ProductApp> {
  AuthViewModel get auth => widget.auth;
  ProductRepository get repository => widget.repository;
  @override
  void dispose() {
    auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Quản lý sản phẩm',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xfff7f7f7),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        errorMaxLines: 3,
      ),
      useMaterial3: true,
    ),
    home: ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        if (auth.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (auth.uid == null) return LoginView(model: auth);
        if (!auth.isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Quản lý sản phẩm')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Tài khoản này không có quyền admin.'),
                    const SizedBox(height: 12),
                    if (auth.error != null)
                      Text(
                        auth.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    FilledButton(
                      onPressed: auth.busy ? null : auth.signOut,
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return ProductsView(
          key: ValueKey(auth.uid),
          repository: repository,
          auth: auth,
        );
      },
    ),
  );
}
