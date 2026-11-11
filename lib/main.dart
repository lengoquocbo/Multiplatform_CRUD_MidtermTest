import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'repositories/auth_repository.dart';
import 'repositories/product_repository.dart';
import 'services/auth_service.dart';
import 'services/product_service.dart';
import 'services/error_message.dart';
import 'viewmodels/auth_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(
      ProductApp(
        auth: AuthViewModel(AuthRepository(AuthService(FirebaseAuth.instance))),
        repository: ProductRepository(
          ProductService(FirebaseFirestore.instance),
        ),
      ),
    );
  } catch (error) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Không thể khởi tạo Firebase: ${errorMessage(error)}'),
          ),
        ),
      ),
    );
  }
}
