# Sửa ảnh URL cũ trên Web

Hiện tượng: sau thao tác đổi ảnh hoặc sắp xếp sản phẩm, Web có thể giữ hình cũ; tải lại trang mới khớp Android.

Nguồn kiểm tra: Flutter SDK 3.32.5 tại máy. Nhánh Image.network với WebHtmlElementStrategy.fallback dùng RawWebImage/ImgElementPlatformView. HtmlElementView nhận src qua creationParams khi tạo view; nếu subtree tái sử dụng với ảnh từ cache, phần HTML có thể giữ src cũ.

Sửa tại lib/views/product_image.dart: đặt ValueKey(url) cho Image.network và Image.memory để thay mới phần hiển thị khi giá trị ảnh thay đổi. Sửa tại lib/views/products_view.dart: hàng danh sách và DataRow có ValueKey(document ID), tránh tái sử dụng hàng theo vị trí sau tìm kiếm/sắp xếp/sửa tên. Không thêm query ngẫu nhiên vào URL, không đổi dữ liệu Firebase hoặc tắt bảo mật trình duyệt.

Kiểm tra thực tế: trang thử tách biệt dùng đúng ProductImage của app và cách cũ, hai ảnh đỏ A/xanh B phục vụ qua origin khác không có header CORS, buộc dùng HTML fallback. Trình duyệt thực hiện A → B → A mà không reload. Ở lần chọn lại A từ cache, cách cũ vẫn hiển thị B (xanh), ProductImage đã sửa hiển thị A (đỏ) đúng. Không tạo hoặc sửa document Firestore trong phép thử.

flutter analyze: No issues found.
flutter test: 22 tests passed.
flutter build web: thành công, bản ứng dụng ở build/web.

Bài kiểm tra Flutter test --platform chrome không vào được test case trong môi trường, đã dừng và không tính là kết quả đạt. Kiểm tra trình duyệt nêu trên được thực hiện bằng trang thử thực tế riêng trong .tmp, không phải dữ liệu thay backend ứng dụng.

Cần tải mới bản Web đang mở một lần để nhận code mới; sau đó thay URL không cần reload để cập nhật ảnh.
