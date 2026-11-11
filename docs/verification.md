# Kết quả kiểm tra ngày 11/11/2026

- `flutter analyze`: No issues found.
- `flutter test`: 8 bài kiểm tra thành công, gồm schema, validation, JSON, hình thay thế, layout ở 320/1024 px và form giữ dữ liệu khi lưu thất bại. Các bài kiểm tra UI dùng fixture riêng trong test.
- `flutter build web`: thành công, kết quả tại `build/web`.
- `firebase deploy --only firestore:rules --project crud-giuaki-quocbo --non-interactive`: thành công; bản cuối biên dịch không có cảnh báo.
- Firebase Authentication: đăng nhập tài khoản admin thật thành công; UID được cấu hình trong source và Rules. Không ghi mật khẩu hoặc ID token vào file.
- Firestore thật: tạo sản phẩm qua API Firebase với client ID token, GET máy chủ xác nhận đúng bốn trường, sửa và GET lại xác nhận. Xóa document thử và GET trả 404.
- Rules thật: người chưa đăng nhập bị chặn; tạo một tài khoản kiểm thử non-admin thật và xác nhận đọc/ghi bị chặn, sau đó xóa tài khoản thử.
- Rules thật: giá âm, sai kiểu, NaN/vô cực; số lượng âm/lẻ; tên rỗng/toàn khoảng trắng; URL HTTP và trường thừa đều bị từ chối.
- JSON: đã xuất dữ liệu thực từ máy chủ vào `data/products.json`, nhập lại với ID thử khác và GET kiểm tra, thử trùng ID bị từ chối. Đã xóa hai document thử; không xóa dữ liệu có sẵn.
- File JSON chứa sản phẩm kiểm thử thật đã từng tồn tại trên Firestore. Không phải dữ liệu nghiệp vụ của cửa hàng; database không giữ lại sản phẩm kiểm thử sau kiểm tra.
- Trình duyệt: đã thử phục vụ bản Web build tại localhost, nhưng công cụ trình duyệt trả `net::ERR_CONNECTION_TIMED_OUT`. Chưa xác nhận đăng nhập/CRUD/ảnh/tải lại trang bằng thao tác UI trình duyệt. Kiểm tra API không thay thế kiểm tra UI.
- Android: `flutter run -d emulator-5554 --debug --verbose` đã BUILD SUCCESSFUL, tạo `build/app/outputs/flutter-apk/app-debug.apk`, cài APK thành công và kết nối Dart VM Service. ADB xác nhận MainActivity của ứng dụng đang hiển thị; đã quan sát trực tiếp màn hình Đăng nhập admin trên Pixel 9. Log tại `build/android-run-kotlin24.log`. Chưa kiểm tra CRUD và ảnh trên Android, chưa xác nhận APK release.
- Đã sửa cấu hình Android: minSdk 24, NDK 27.0.12077973, Kotlin 2.4.0 và compilerOptions DSL; tắt Kotlin incremental compilation để tránh lỗi cache khi source ở ổ D: và Pub cache ở ổ C:.
- `flutter doctor` vẫn từng cảnh báo một số Android licenses chưa chấp thuận; lần debug build thực tế đã hoàn thành. Người dùng có thể xử lý các license còn thiếu bằng `flutter doctor --android-licenses`.
- Chưa tạo ảnh chụp, file Word, video hoặc link GitHub/video. Yêu cầu hiện tại chỉ chuẩn bị danh sách ảnh và kịch bản trong `docs/bao-cao-demo.md`.

## Kiểm tra tiếp trên máy người dùng

```powershell
flutter run -d chrome
```

Đăng nhập tài khoản admin, thêm sản phẩm của bạn, kiểm tra bốn trường trong Firebase Console, tải lại trang và kiểm tra dữ liệu còn tồn tại. Thử sửa/xóa, URL ảnh lỗi và xuất/nhập JSON. Chỉ xóa sản phẩm bạn tạo.

```powershell
flutter doctor --android-licenses
flutter devices
flutter run -d <device-id>
```

Xem `docs/bao-cao-demo.md` cho kiểm tra giao diện và video demo.

## Cập nhật ảnh và Excel

Kết quả mới nhất (18 tests, Web/Android debug build và UI Web thực tế) nằm trong [media-excel-verification.md](media-excel-verification.md). Các kết quả bên trên thuộc bản trước cập nhật.
