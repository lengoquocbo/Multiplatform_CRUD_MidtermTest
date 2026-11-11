# Kiểm tra cập nhật ảnh và Excel – 11/11/2026

## Lệnh và kết quả

- `flutter analyze`: No issues found.
- `flutter test`: 18 tests thành công. Có test ảnh EXIF, ảnh nhiễu phải nén, ảnh rất hẹp, giới hạn 5 MB/150 KB, từ chối file HTML, Data URI sai, URL quá dài; debounce 500 ms, hủy chọn/chụp giữ ảnh cũ; XLSX đảo cột/trim/hàng trống, công thức, ảnh nhúng so với drawing trống, ô trống đã format ở hàng xa; file mẫu thật; cảnh báo trùng và nhập lỗi giữa chừng không nhập lại; các tests model/layout cũ vẫn qua.
- `flutter build web`: thành công, đã build lại sau `flutter clean` và `flutter pub get` để sinh đúng danh sách plugin Web. Đã đối chiếu registrant có Auth, Camera, Firestore, file_picker, file_saver và Core; không sửa tay file do Flutter sinh.
- `flutter build apk --debug --verbose`: BUILD SUCCESSFUL, có plugin camera_android_camerax. Đây là kiểm tra build bản cập nhật, chưa phải kiểm tra chụp ảnh hoặc nhập Excel trên Android. Lần `flutter clean` sau đó đã xóa artifact/log trong build; kết quả build đã quan sát trước khi clean. Lần chạy `flutter run` tiếp theo sẽ tự build lại APK.
- `firebase deploy --only firestore:rules --project crud-giuaki-quocbo --non-interactive`: thành công, Rules mới đã có trên Firebase; giữ UID admin và đúng bốn trường, chặn ảnh quá dài.

## Mạng và Firestore thực

`tools/check_url_images.dart` dùng chính helper native của app: ảnh HTTPS thật giải mã thành công; HTML `https://www.google.com/` bị từ chối. Một phép thử với example.com gặp CERTIFICATE_VERIFY_FAILED trên Dart của máy này; không bỏ kiểm tra TLS, đã dùng một nguồn HTML có chứng chỉ phù hợp để kiểm tra lại.

`tools/prepare_media_check.dart` dùng cùng xử lý ảnh và parser OOXML của app để chuẩn bị payload JPEG và đọc file mẫu thật. `tools/check_media_firestore.py` đã:

- Lưu JPEG Data URI được xử lý thật, đăng nhập lại và GET từ máy chủ để kiểm tra nguyên vẹn ảnh và đúng bốn trường.
- Xác nhận Rules từ chối prefix/Base64 sai, Data URI quá dài, URL HTTPS quá dài và người chưa đăng nhập.
- Lưu hai hàng đọc từ XLSX mẫu và GET từng document kiểm tra đủ bốn trường/giá trị.
- Xóa đúng document thử do công cụ tạo, GET xác nhận 404.

Chi tiết: `media-excel-live-check.json`. Không lưu mật khẩu/token trong source hoặc file dữ liệu.

## UI trình duyệt thực

Đã phục vụ tạm Web build trên localhost và mở bằng trình duyệt của công cụ. Bản cũ tại 127.0.0.1 còn giữ cache plugin gây channel-error; đã clean/build lại, xác nhận plugin được sinh đầy đủ và kiểm tra trên origin localhost mới. Không tắt CORS hoặc kiểm tra chứng chỉ. Khi phát triển gặp cache cũ, dùng `flutter clean`, `flutter pub get`, build/run lại và tải mới trang; `flutter run -d chrome` dùng chế độ phát triển.

Đã thực hiện:

1. Đăng nhập admin thành công và đọc danh sách Firestore có sẵn.
2. Nhập URL trang HTML, chờ debounce và quan sát lỗi xem trước.
3. Mở hộp chọn file thật, chọn JPEG từ bytes; nguồn chuyển sang File và có ảnh xem trước.
4. Lưu sản phẩm thử, quan sát ảnh Data URI trong danh sách; tải lại trang và ảnh vẫn hiển thị.
5. Mở Nhập Excel, chọn XLSX thật qua file chooser; xem trước đúng hai hàng, 0 lỗi.
6. Xác nhận nhập; UI báo đã lưu 2/2 và khóa nút nhập lại.
7. Tải lại trang, cả hai sản phẩm từ Excel và ảnh URL đều hiển thị, ảnh Data URI vẫn còn.
8. Đăng nhập API mới, đọc máy chủ xác nhận đúng ba document tạo qua UI, mỗi document chỉ có bốn trường. Ảnh file là Data URI, không phải URL HTML còn trong ô nhập.
9. Xóa đúng ba ID thử theo tên riêng biệt, GET xác nhận 404; đọc lại dữ liệu có sẵn xác nhận không thay đổi.

Chi tiết: `media-excel-ui-check.json`. `excel-import-ui.jpg` là ảnh chụp UI thật lúc nhập hoàn tất, trước khi dọn dữ liệu thử; có thể dùng làm bằng chứng kiểm tra, không phải dữ liệu hàng hóa thật.

## Chưa kiểm tra

- Chụp bằng webcam/camera thật, hộp xin quyền và từ chối quyền trên phần cứng.
- Các thao tác mới chọn file/chụp ảnh/nhập XLSX ở runtime Android; đã kiểm tra debug build.
- Android APK release.

Code camera dùng CameraController/CameraPreview thật và có dispose controller; chưa dùng kết quả build để khẳng định đã kiểm tra phần cứng.

## Kiểm tra thủ công tiếp

```powershell
flutter run -d chrome
flutter run -d emulator-5554
```

- URL ảnh không đuôi và URL HTML; chờ 500 ms. Thử mạng lỗi/hotlink bị chặn, quan sát tải/lỗi.
- Chọn JPEG có EXIF, PNG trong suốt, file giả ảnh và file >5 MB; hủy chọn giữ ảnh cũ.
- Mở Chụp ảnh trên localhost/HTTPS và Android, tự cấp/từ chối quyền; chụp rồi hủy, đóng màn hình kiểm tra đèn camera tắt. Không cấp quyền microphone vì audio đã tắt.
- Đổi URL/file/camera, lưu, tải lại và kiểm tra duy nhất trường image với đúng nguồn đã chọn.
- XLSX đảo cột, hàng trống, giá âm/NaN, số lượng lẻ, công thức có cache, ảnh nhúng/Base64 và tên trùng. File lỗi không được nhập.
- Ngắt mạng khi nhập nhiều dòng: ghi nhận số đã lưu/hàng lỗi; kiểm tra máy chủ trước khi tạo file còn thiếu, không nhập lại nguyên file.
