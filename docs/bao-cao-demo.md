# Chuẩn bị báo cáo Word và video

Chưa có ảnh chụp hoặc video được tạo trong lần triển khai này. Tự chụp bằng dữ liệu demo của bạn; không chụp mật khẩu/token.

## Ảnh cần chụp

1. Trang đăng nhập, sau đó trang quản lý với phiên admin.
2. Form thêm đủ tên, giá, số lượng và URL HTTPS, ảnh xem trước.
3. Danh sách desktop có ảnh, tên, giá và số lượng.
4. Form sai: tên trống, giá âm/không phải số, số lượng lẻ, URL HTTP.
5. Form sửa có dữ liệu cũ và kết quả sau lưu.
6. Hộp xác nhận xóa có tên sản phẩm; kết quả sau xóa.
7. Tìm kiếm có kết quả và không có kết quả.
8. Firebase Console: collection products và document chỉ có đúng bốn trường; ID ở ngoài dữ liệu.
9. Rules có UID admin và kiểm tra bốn trường; không chụp tài khoản bí mật.
10. File Excel xuất và màn hình Nhập Excel: đúng bốn header, xem trước, lỗi theo ô, công thức và cảnh báo trùng tên.
11. Giao diện ở điện thoại hoặc emulator Android: ảnh, tên, giá và số lượng, form cuộn được khi mở bàn phím.
12. Kết quả analyze/test/build của máy thực hiện.

## Kịch bản video 4–6 phút

- Giới thiệu ngắn Flutter/Dart, MVVM và Firebase Auth/Firestore, mở các thư mục trách nhiệm.
- Đăng nhập admin; cho thấy danh sách ban đầu.
- Thêm sản phẩm hợp lệ và mở Firestore Console xác nhận bốn trường.
- Tải lại trang và đăng nhập lại nếu cần; chứng minh dữ liệu vẫn tồn tại.
- Tìm theo tên; sửa giá/số lượng và kiểm tra document trên Console.
- Nhập đầu vào sai và cho thấy không lưu được; thử ảnh lỗi và ảnh HTTPS hợp lệ.
- Xuất Excel; mở file và chỉ rõ bốn cột, ảnh URL/ảnh JPEG nhúng; chọn XLSX, xem trước rồi xác nhận nhập; thử file lỗi/công thức và tên trùng để thấy lỗi/cảnh báo.
- Xóa sản phẩm do bạn tạo, xác nhận có tên và kiểm tra database.
- Đăng xuất; dùng tài khoản non-admin đã chuẩn bị để thấy không có quyền; không hiển thị mật khẩu.
- Hiển thị trên điện thoại; nếu chỉ dùng cửa sổ Web thu nhỏ thì gọi đúng là Web ở kích thước điện thoại, không gọi là đã chạy Android.
- Nêu giới hạn: ảnh bằng URL, chưa upload; Android chỉ báo chạy được khi thực sự đã chạy.

## Kiểm tra thủ công

- Tắt mạng rồi lưu: không báo thành công; form không mất dữ liệu. Bật mạng và thử lại.
- Thu nhỏ còn 320 px, nhập tên dài, mở bàn phím, cuộn đến Lưu/Hủy.
- Dùng HTTPS trả lỗi hoặc dữ liệu không phải ảnh: phải có hình thay thế.
- Không xóa sản phẩm có sẵn của người khác. Chỉ dùng các sản phẩm bạn tạo cho demo.

## Bổ sung ảnh và camera

Chụp các nguồn URL/file/camera với cùng vùng xem trước, hủy giữ ảnh cũ, lỗi URL HTML/file giả ảnh, Data URI sau tải lại trang, XLSX nhập thành công và nhập lỗi giữa chừng. Có ảnh thật của lần kiểm tra UI tại `excel-import-ui.jpg`; dữ liệu trong ảnh là dữ liệu thử đã được dọn. Camera/webcam thật chưa được kiểm tra trong lần cập nhật này, chỉ ghi kết quả sau khi tự chạy trên thiết bị.
