# Đổi Xuất JSON thành Xuất Excel

- UI: nút Xuất Excel, tạo products.xlsx từ dữ liệu máy chủ qua Repository/ViewModel.
- Service: excel_export_service.dart đóng gói XLSX; excel_file_service.dart lưu bytes bằng file_saver. Không thêm dependency runtime hoặc sửa Firebase/Rules.
- File có đúng name, price, soluong, image; tên bắt đầu dấu = được ghi literal text, không tạo công thức. Số lớn được giữ bằng text khi vượt 15 chữ số của Excel.
- JPEG Data URI được nhúng đầy đủ trong xl/media và gắn với cột image của đúng hàng. URL ảnh giữ nguyên. Không làm mất ảnh do giới hạn ký tự ô.
- File có ảnh nhúng không nhập lại được bằng Nhập Excel hiện tại vì bộ nhập yêu cầu URL HTTPS; UI và README có giải thích. File chỉ dùng URL được kiểm tra round-trip qua parser nhập hiện có.
- flutter analyze: No issues found.
- flutter test test/excel_export_test.dart: 4 tests passed, gồm JPEG lớn nguyên vẹn/vị trí cột image, bốn cột và round-trip/số lớn/text an toàn, danh sách rỗng, từ chối dữ liệu chữ quá giới hạn.
- flutter build web: thành công.
- Chưa thao tác tải file qua UI hoặc mở file bằng Microsoft Excel trong lần thay đổi này; tests đã đọc XLSX bằng thư viện excel và parser OOXML của ứng dụng.
