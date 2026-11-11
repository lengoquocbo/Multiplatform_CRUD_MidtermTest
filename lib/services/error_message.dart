import 'package:firebase_core/firebase_core.dart';

String errorMessage(Object error) {
  if (error is FormatException) return error.message;
  if (error is StateError) return error.message;
  if (error is FirebaseException) {
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Email hoặc mật khẩu không đúng.',
      'invalid-email' => 'Email không hợp lệ.',
      'user-disabled' => 'Tài khoản bị vô hiệu hóa.',
      'too-many-requests' => 'Quá nhiều yêu cầu. Hãy thử lại sau.',
      'operation-not-allowed' =>
        'Cần bật Email/Password trong Firebase Authentication.',
      'permission-denied' =>
        'Không có quyền truy cập. Kiểm tra UID admin và Security Rules.',
      'unauthenticated' => 'Phiên đăng nhập hết hạn. Hãy đăng nhập lại.',
      'unavailable' || 'network-request-failed' =>
        'Không kết nối được Firebase. Kiểm tra mạng và thử lại.',
      _ => 'Firebase báo lỗi (${error.code}). Hãy thử lại.',
    };
  }
  return 'Thao tác thất bại. Kiểm tra mạng và thử lại.';
}
