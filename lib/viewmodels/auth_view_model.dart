import 'dart:async';
import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';
import '../services/error_message.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository) {
    _subscription = _repository.sessions.listen(
      (value) {
        uid = value;
        loading = false;
        notifyListeners();
      },
      onError: (Object value) {
        error = errorMessage(value);
        loading = false;
        notifyListeners();
      },
    );
  }
  final AuthRepository _repository;
  late final StreamSubscription<String?> _subscription;
  String? uid;
  String? error;
  bool loading = true;
  bool busy = false;
  bool get isAdmin => _repository.isAdmin(uid);
  bool get configured => _repository.configured;
  Future<void> signIn(String email, String password) async {
    if (busy) return;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim()) ||
        password.isEmpty) {
      error = 'Nhập email hợp lệ và mật khẩu.';
      notifyListeners();
      return;
    }
    await _perform(() => _repository.signIn(email.trim(), password));
  }

  Future<void> signOut() => _perform(_repository.signOut);
  Future<void> _perform(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (value) {
      error = errorMessage(value);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
