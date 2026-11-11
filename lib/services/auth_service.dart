import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService(this._auth);
  final FirebaseAuth _auth;
  Stream<String?> get sessions =>
      _auth.authStateChanges().map((user) => user?.uid);
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();
}
