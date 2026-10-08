# Mini-Project 3: OCR Expense Tracker & Receipt Parser (Flutter & Dart)

Một ứng dụng quản lý chi tiêu cá nhân thông minh kết hợp trí tuệ nhân tạo On-Device (**Google ML Kit Text Recognition**) và biểu đồ trực quan động được vẽ thuần bằng **Flutter CustomPainter** (Native Canvas, không phụ thuộc thư viện chart bên ngoài).

---

## 🌟 Tính Năng Nổi Bật (Key Features)

### 1. Camera Capture & Framing Crop Guide
- **Viewfinder trực tiếp**: Chụp hoá đơn thời gian thực với toggle Flash và chạm lấy nét (Tap to Focus).
- **Khung định vị (Framing Crop Overlay)**: Hiệu ứng quét laser chuyển động giúp người dùng căn chỉnh hoá đơn chính xác.
- **Linh hoạt đầu vào**: Hỗ trợ chụp từ camera, chọn ảnh từ thư viện (Gallery), hoặc dùng các mẫu hoá đơn test tích hợp sẵn.

### 2. On-Device Text Recognition & Heuristic Regex Engine
- Tích hợp **`google_mlkit_text_recognition`** xử lý offline hoàn toàn trên thiết bị (độ trễ sub-100ms, bảo mật dữ liệu, 0 chi phí cloud).
- **Bộ máy Regex Heuristic đa năng**:
  - **Trích xuất số tiền**: Nhận diện tiền tệ Việt Nam (VND, VNĐ, đ) và quốc tế (185.000 đ, 75,000 VND, 150 000). Ưu tiên các dòng chứa từ khóa `TỔNG CỘNG`, `THÀNH TIỀN`, `TỔNG THANH TOÁN`, `TOTAL`, v.v.
  - **Trích xuất ngày tháng**: `DD/MM/YYYY`, `DD-MM-YYYY`, `YYYY-MM-DD` hoặc `Ngày ... tháng ... năm ...`.
  - **Trích xuất tên cửa hàng (Merchant)**: Nhận diện theo header hoá đơn & từ điển thương hiệu phổ biến (WinMart, Highlands Coffee, Fahasa, Circle K, Co.opmart, Phúc Long, Grab, v.v.).
  - **Gợi ý danh mục tự động**: Tự động phân loại vào 5 nhóm: `Food`, `Study`, `Travel`, `Gear`, `Entertainment`.
- **Màn hình Review tương tác**: Cho phép người dùng kiểm tra, chỉnh sửa thông tin và xem cả văn bản OCR thô (Raw OCR text) trước khi lưu.

### 3. Local SQLite Storage & Lifecycle
- Cơ sở dữ liệu offline **SQLite (`sqflite`)** bảo mật và tin cậy.
- Phân loại 5 danh mục chuẩn: **Ăn uống (Food)**, **Học tập (Study)**, **Di chuyển (Travel)**, **Thiết bị (Gear)**, **Giải trí (Entertainment)**.
- Tự động lưu cache ảnh hoá đơn trong thư mục bộ nhớ ứng dụng.
- Tìm kiếm, lọc theo danh mục, sửa, xoá giao dịch.

### 4. Custom Canvas Visualizations với `CustomPainter` (Zero 3rd-party chart library)
- **Animated Donut / Pie Chart**:
  - Vẽ trực tiếp trên Canvas với cung tròn (`drawArc`), bóng mờ (`blur`) và hiệu ứng chuyển động xoay `CurvedAnimation`.
  - Tương tác chạm chip danh mục để làm nổi bật và hiển thị tỉ lệ phần trăm + số tiền chi tiết.
- **Animated Weekly Spending Bar Chart**:
  - Vẽ cột bo góc (`drawRRect`) cho 7 ngày gần nhất với hiệu ứng cột vươn cao từ đáy.
  - Chạm vào từng cột để hiển thị tooltip số tiền và ngày giao dịch chi tiết.

---

## 📁 Cấu Trúc Thư Mục Dự Án (`lib/`)

```
lib/
├── main.dart                          # Khởi tạo Flutter, Database FFI, Theme & Provider
├── core/
│   ├── constants/
│   │   ├── app_colors.dart            # Bảng màu Dark Theme hiện đại
│   │   └── app_categories.dart        # 5 danh mục: Food, Study, Travel, Gear, Entertainment
│   ├── database/
│   │   └── db_helper.dart             # SQLite CRUD, tính tổng, thống kê danh mục & tuần
│   └── utils/
│       ├── currency_formatter.dart    # Format tiền tệ VND (185.000 đ)
│       └── date_formatter.dart        # Format ngày DD/MM/YYYY
├── models/
│   ├── ocr_result_model.dart          # Dữ liệu bóc tách từ OCR
│   └── transaction_model.dart         # Model giao dịch SQLite
├── providers/
│   └── expense_provider.dart          # State Management cho giao dịch và trạng thái quét
├── services/
│   ├── ocr_service.dart               # Tích hợp Google ML Kit Offline OCR
│   └── receipt_parser.dart            # Heuristic Regex Engine bóc tách thông tin
└── views/
    ├── main_navigation_screen.dart    # Thanh điều hướng Bottom Bar + Floating Scanner Action
    ├── home/
    │   ├── home_screen.dart           # Dashboard tổng quan & danh sách chi tiêu
    │   └── widgets/
    │       └── transaction_tile.dart  # Item giao dịch trong danh sách
    ├── scanner/
    │   ├── camera_scanner_screen.dart # Viewfinder chụp ảnh, flash, laser scan & preset selector
    │   └── review_receipt_screen.dart # Form xem trước & chỉnh sửa trước khi lưu
    ├── analytics/
    │   └── analytics_screen.dart      # Màn hình báo cáo biểu đồ
    ├── transactions/
    │   └── transaction_detail_screen.dart # Chi tiết giao dịch + xem ảnh hoá đơn
    └── widgets/
        ├── custom_donut_chart.dart    # Donut Chart vẽ thuần Canvas bằng CustomPainter
        └── custom_bar_chart.dart      # Bar Chart vẽ thuần Canvas bằng CustomPainter
```

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### Yêu cầu môi trường:
- Flutter 3.x (đã kiểm thử trên **Flutter 3.32.5 / Dart 3.8.1**)
- Android SDK (minSdkVersion 21+)
- Thiết bị thật hoặc giả lập Android / Windows

### Các bước thực hiện:

1. **Clone repository hoặc tải source code**:
   ```bash
   git clone <your-repo-url>
   cd Minilab3
   ```

2. **Cài đặt các gói phụ thuộc (Dependencies)**:
   ```bash
   flutter pub get
   ```

3. **Chạy Unit Test**:
   ```bash
   flutter test
   ```

4. **Chạy ứng dụng ở chế độ Debug**:
   ```bash
   # Chạy trên thiết bị Android / Giả lập
   flutter run
   ```

5. **Build file APK Release nộp bài**:
   ```bash
   flutter build apk --release
   ```
   File APK đầu ra nằm tại: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📦 Submission Deliverables (Gói Nộp Bài)

1. **🌐 Live Demo / Release APK**:
   - Link tải APK (`app-release.apk`): *[Cập nhật link GitHub Releases hoặc Google Drive tại đây]*
   - Video Demo (quay quét hoá đơn & biểu đồ): *[Cập nhật link YouTube / Drive tại đây]*
2. **💻 GitHub Repository**:
   - Đã cấu hình mã nguồn sạch, đạt chuẩn phân tích tĩnh `flutter analyze` và đã vượt qua 100% `flutter test`.
