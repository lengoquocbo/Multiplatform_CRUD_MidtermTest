import '../config/admin_access.dart';
import '../services/auth_service.dart';

class AuthRepository {
  AuthRepository(this._service);
  final AuthService _service;
  Stream<String?> get sessions => _service.sessions;
  bool isAdmin(String? uid) => uid != null && adminUids.contains(uid);
  bool get configured => adminUids.isNotEmpty;
  Future<void> signIn(String email, String password) =>
      _service.signIn(email, password);
  Future<void> signOut() => _service.signOut();
}
