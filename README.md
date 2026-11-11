# Quản lý sản phẩm – giữa kì

Flutter/Dart, Firebase project `crud-giuaki-quocbo`, Web và Android. Giao diện tiếng Việt, desktop dùng bảng, dưới 900 px dùng danh sách. Firebase SDK gọi trực tiếp Auth/Firestore, không có server riêng, Storage hoặc dịch vụ lưu ảnh ngoài.

## Chức năng và dữ liệu

Đăng nhập/đăng xuất admin bằng email/password; danh sách realtime; thêm, sửa, xóa có xác nhận; tìm kiếm theo tên; ảnh URL/file/camera; nhập XLSX có xem trước; xuất Excel để nộp bài. Lỗi lưu giữ nội dung form, nút gửi bị khóa khi xử lý. Mọi ghi dữ liệu dùng transaction và chỉ báo thành công sau khi máy chủ xác nhận.

Collection `products`. Document có đúng bốn trường:

| Trường | Kiểu và điều kiện |
| --- | --- |
| name | String trim, không rỗng |
| price | Number hữu hạn, không âm |
| soluong | Int từ 0 đến 9007199254740991 để giữ chính xác trên Web |
| image | HTTPS URL tối đa 2048 ký tự hoặc JPEG Data URI tối đa 204823 ký tự |

Document ID nằm ngoài dữ liệu. Không thêm trường khác. Giá hiển thị định dạng Việt Nam với đơn vị đồng; làm tròn phần hiển thị, giá gốc vẫn được lưu. Snapshot cache được ghi rõ chưa được máy chủ xác nhận. Xuất Excel đọc `Source.server`.

## MVVM

- `models/`: Product, ImageValue và dữ liệu xem trước Excel.
- `views/`: Material UI, form, bảng/danh sách, camera preview và xem trước nhập Excel. `ProductImage` dùng chung trong form, bảng, danh sách; hỗ trợ URL cũ và Data URI.
- `viewmodels/`: ChangeNotifier cho phiên đăng nhập, danh sách, form, nguồn ảnh, camera và nhập Excel. Validation và điều phối không nằm trong widget.
- `repositories/`: điều phối dữ liệu, đọc máy chủ và lưu theo ID.
- `services/`: Firebase Auth/Firestore, file picker, kiểm tra URL ảnh, xử lý/nén ảnh, parser XLSX.
- `main.dart`: khởi tạo Firebase và ghép dependency; `app.dart`: theme và chuyển màn hình theo phiên admin.

Các hàm thuần `image_processing.dart` và `excel_parser.dart` được dùng chung trong app, unit tests và công cụ kiểm tra máy chủ. Không truy cập Firebase trong widget. Không có Firebase Admin SDK/service account.

## Hình ảnh

Ba cách dùng chung một vùng xem trước:

1. Nhập URL HTTPS: sau 500 ms ngừng nhập sẽ kiểm tra ảnh và xem trước. Có trạng thái tải và lỗi. URL không cần đuôi jpg/png; trang HTML không được coi là ảnh. Web dùng khả năng decode ảnh của trình duyệt, không yêu cầu đọc pixel từ nguồn khác miền; widget có HTML fallback cho CORS. Không tắt bảo mật, không dùng proxy ngoài. Nguồn có thể từ chối hotlink hoặc không còn tồn tại, khi đó có thông báo/hình thay thế. Trên Android kiểm tra bytes ảnh URL, tối đa 5 MB cho bước xác thực và tối đa 32 triệu pixel.
2. Chọn file: Web/Android đọc bytes, kiểm tra dữ liệu ảnh thật; không dựa vào đuôi file. Đầu vào tối đa 5 MB và 32 triệu pixel. Định dạng đọc phụ thuộc decoder `image` (JPEG/PNG/WebP/GIF/BMP/TIFF phổ biến); ảnh động lấy khung hình để tạo JPEG.
3. Chụp ảnh: mở `CameraPreview` thật, Android dùng camera, Web dùng webcam qua `camera_web`, không mở hộp chọn file. Web cần localhost hoặc HTTPS. App yêu cầu quyền camera khi mở; từ chối quyền/không có camera sẽ hiển thị lỗi. Tắt audio. Controller được giải phóng khi đóng màn hình, chụp xong hoặc chuyển app sang trạng thái inactive; có xử lý khởi tạo lại khi quay lại.

Ảnh file/camera được sửa hướng EXIF, thu nhỏ giữ tỉ lệ với cạnh dài tối đa 800 px, chuyển nền trong suốt thành trắng, nén JPEG bằng giảm chất lượng rồi giảm kích thước nếu cần để không vượt 150 × 1024 bytes. Lưu duy nhất `data:image/jpeg;base64,...` vào `image`. Không lưu đường dẫn máy, blob URL hay bytes ở trường phụ. Metadata không được chép vào nền ảnh đầu ra. Hủy chọn/chụp giữ nguồn và ảnh hiện tại. Chọn ảnh mới thành công thay nguồn đang dùng; nhập lại URL hoặc bấm Dùng URL đã nhập sẽ chuyển về nguồn URL.

Rules kiểm tra prefix/alphabet Base64 và độ dài; Rules không thể giải mã đầy đủ bitstream JPEG. App kiểm tra nội dung và nén bytes thật trước khi lưu. ProductImage có hình thay thế nếu ảnh hỏng hoặc tải lỗi. JPEG Data URI tối đa khoảng 205 KB chuỗi, nằm dưới giới hạn document Firestore.

## Nhập Excel

Màn hình chính → Nhập Excel → Chọn file XLSX → xem toàn bộ hàng, lỗi và cảnh báo → Xác nhận nhập → Đồng ý nhập.

- Nhận `.xlsx` từ bytes trên Web/Android, tối đa 10 MB, nội dung giải nén tối đa 25 MB, tối đa 1000 hàng dữ liệu. Giới hạn 100 cột dùng để kiểm tra lỗi ngoài vùng dữ liệu.
- Chỉ worksheet đầu tiên theo `workbook.xml`; hàng 1, cột A–D gồm đúng `name`, `price`, `soluong`, `image`. Có thể đảo thứ tự bốn cột vì ánh xạ theo tên. Không thêm tiêu đề phụ/dòng ghi chú trước header.
- Trim chuỗi, bỏ hàng hoàn toàn trống; giữ số hàng gốc để báo lỗi. Giá hữu hạn không âm, số lượng nguyên không âm. Chuỗi số hợp lệ cũng được chuyển thành number. Không nhận ô boolean, lỗi Excel hoặc kiểu ngày ISO cho cột số.
- Cột image chỉ nhận URL HTTPS tối đa 2048 ký tự, không nhận Data URI/Base64. Không nhận ảnh nhúng trong worksheet; drawing trống được bỏ qua. Không tải toàn bộ URL ảnh khi kiểm tra Excel; kiểm tra định dạng URL và hiển thị ảnh bằng widget sau nhập.
- Mọi ô công thức, kể cả có giá trị cache hoặc công thức chia sẻ, đều bị từ chối và báo tọa độ ô. Không tính công thức; hãy Paste Values trước khi nhập.
- Parser OOXML dùng `archive` và `xml`, đọc shared strings/inline strings và dữ liệu số, không phụ thuộc style của Excel. Không có công thức hoặc macro được thực thi.
- File có bất kỳ lỗi nào sẽ không được nhập. Xem trước báo lỗi theo hàng/cột, cảnh báo tên trùng trong file và với dữ liệu đọc từ Firestore trước khi xác nhận. Tên trùng vẫn được nhập nếu người dùng xác nhận; dữ liệu hiện có không bị thay thế.
- Mỗi dòng tạo document ID mới bằng Firestore SDK, không ghi đè/xóa document cũ. Ghi lần lượt để biết chính xác số dòng đã được xác nhận. Khi lỗi, dừng và báo số đã lưu cùng hàng lỗi; không tự nhập lại hoặc cho bấm lại trong phiên đó. Nếu mất kết nối, kết quả hàng đang lỗi có thể chưa xác định, cần kiểm tra máy chủ rồi tạo file chỉ gồm các hàng còn thiếu. Đóng màn hình và nhập lại nguyên file có thể tạo sản phẩm trùng; hãy xem cảnh báo.

File mẫu: [products-template.xlsx](outputs/01a1c960-de00-73c2-b575-f2c01d7b1f74/products-template.xlsx), có một worksheet, đúng bốn cột và hai hàng minh họa. Hai sản phẩm mẫu không phải dữ liệu nghiệp vụ thật. Chỉnh dữ liệu trước khi nhập nếu cần.

## Firebase, admin và Security Rules

Giữ cấu hình thật `lib/firebase_options.dart`, `android/app/google-services.json`, Gradle và `firebase.json`. Chỉ cấu hình Web/Android:

```powershell
dart pub global run flutterfire_cli:flutterfire configure --project=crud-giuaki-quocbo --platforms=web,android
```

Firebase Authentication cần bật Email/Password. Không có đăng ký công khai trong UI, không hardcode mật khẩu. Admin UID đã xác thực `EDYSRz60IQVAF7wOZbmBvlRS2643` trong `lib/config/admin_access.dart` và `firestore.rules`. Khi đổi admin, cập nhật cả hai, deploy Rules và build lại. UID không phải mật khẩu/bí mật. Rules mới đã được triển khai lên Firebase, giữ điều kiện admin và đúng bốn trường, kiểm tra kiểu/giá/số lượng/tên và giới hạn ảnh. Mọi đường dẫn khác bị từ chối mặc định.

```powershell
firebase deploy --only firestore:rules --project crud-giuaki-quocbo --non-interactive
```

Rules là lớp bảo vệ máy chủ; kiểm tra quyền trong Flutter chỉ điều khiển giao diện. Không mở database công khai.

## Cài đặt và chạy

Flutter 3.32.5 / Dart 3.8.1. `pubspec.lock` giữ phiên bản đã giải quyết cho SDK này. Package chính: firebase_core, cloud_firestore, firebase_auth, intl, file_picker, file_saver, image, camera, http, web, archive, xml. `excel` chỉ nằm trong dev_dependencies để sinh fixture kiểm thử, không phải parser runtime của ứng dụng.

```powershell
flutter pub get
flutter run -d chrome
flutter analyze
flutter test
flutter build web
```

Android cần API 24+, Kotlin 2.4.0, NDK 27.0.12077973. Tắt Kotlin incremental compilation để tránh lỗi cache khác ổ đĩa giữa project D: và Pub cache C:. Camera permission đến từ manifest plugin, quyền INTERNET đã có trong manifest app.

```powershell
flutter doctor --android-licenses
flutter emulators --launch Pixel_9
flutter devices
flutter run -d emulator-5554
```

Bản trước cập nhật ảnh/Excel đã chạy màn hình đăng nhập trên Pixel 9. Không dùng kết quả đó để khẳng định camera và nhập Excel mới đã được kiểm tra trên Android; xem kết quả mới ở `docs/media-excel-verification.md`.

## Xuất Excel và công cụ JSON

UI đã đổi thành Xuất Excel, đọc trực tiếp máy chủ và tạo `products.xlsx` với worksheet Products, đúng bốn cột `name`, `price`, `soluong`, `image`, không xuất document ID. Web tải file; Android lưu bằng file_saver trong dữ liệu ứng dụng. Ảnh HTTPS được giữ dạng chuỗi URL. JPEG Data URI được nhúng thành ảnh ở cột image, giữ nguyên bytes JPEG để tránh giới hạn 32.767 ký tự mỗi ô; không cắt chuỗi ảnh. File chỉ có URL có thể nhập lại qua Nhập Excel để tạo ID mới. File có ảnh nhúng là báo cáo và bị bộ nhập Excel hiện tại từ chối theo quy tắc chỉ nhận URL HTTPS; UI có thông báo khi xuất loại này. Số vượt độ chính xác 15 chữ số của Excel được ghi dạng text để giữ nguyên giá trị, bộ nhập vẫn đọc được số dạng text. Tên quá dài hoặc ký tự điều khiển không hợp lệ sẽ báo lỗi, không tạo file thiếu dữ liệu. Mỗi document Firestore vẫn chỉ có bốn trường; dữ liệu trên máy chủ không bị thay đổi khi xuất.

Công cụ CLI JSON cũ vẫn dùng được, đã hỗ trợ Data URI và không ghi đè dữ liệu/file hiện có:

```powershell
python tools/firestore_data.py export data/products-new.json
python tools/firestore_data.py import data/products-new.json
```

Script hỏi email/mật khẩu, dùng Firebase API với client credentials và không lưu token/mật khẩu. Import JSON tối đa 100 sản phẩm, commit nguyên tử có precondition không tồn tại ID. Không có Admin SDK/server riêng. `data/products.json` cũ chứa sản phẩm kiểm thử thực đã xuất từ Firestore và sau đó xóa khỏi database, không phải hàng tồn kho thật.

## Kiểm tra, báo cáo và giới hạn

Xem `docs/media-excel-verification.md`, `docs/media-excel-live-check.json` và các tests. Thư mục test có fixture riêng, không thay backend khi chạy app. Đã kiểm tra UI Web thật cho đăng nhập, URL HTML, chọn file, lưu ảnh/tải lại và nhập XLSX/tải lại; bằng chứng API không thay thế thử webcam hoặc runtime Android. Xem thêm `docs/media-excel-ui-check.json` và ảnh thật `docs/excel-import-ui.jpg`. Camera, quyền camera và CORS còn phụ thuộc thiết bị/trình duyệt/nguồn ảnh. Không có Firebase Storage/upload server.

`docs/bao-cao-demo.md` là danh sách ảnh/kịch bản ban đầu; bổ sung cảnh nhập URL tự preview, chọn file, chụp webcam/Android, hủy giữ ảnh cũ, XLSX đúng/sai/công thức/trùng tên, nhập lỗi giữa chừng và Xuất Excel. Chỉ dùng ảnh chụp/video thực tế khi làm báo cáo. Danh sách vẫn tải toàn bộ products, phù hợp quy mô bài giữa kì; chưa phân trang hoặc xử lý xung đột sửa đồng thời.

## Cập nhật ảnh Web không cần reload

Ảnh có khóa theo URL và hàng có khóa theo document ID để tạo lại HTML view khi đổi ảnh, tránh giữ hình cũ khi lấy từ cache hoặc đổi vị trí sản phẩm. Đã kiểm tra A → B → A trên trình duyệt với nhánh HTML fallback; xem `docs/web-image-refresh-fix.md`. Cần tải mới bản Web một lần sau cập nhật code.
