# Plan: Triển khai Giao diện Xác thực Flutter (Auth UI)

## 1. Tổng quan
- **Mục tiêu**: Xây dựng toàn bộ hệ thống giao diện xác thực (Auth UI), quản lý luồng điều hướng, quản lý trạng thái, và tích hợp API backend NestJS trong thư mục `fe/` cho hệ thống thư viện.
- **Phạm vi giao diện**: 14 màn hình từ khởi động chọn cổng, đăng nhập, đăng ký, xác thực OTP, quên mật khẩu, đặt lại mật khẩu cho cả 2 đối tượng (Độc giả & Nhân viên), cùng trang chủ tối thiểu sau đăng nhập.
- **Tiêu chuẩn thiết kế**: Tuân thủ tuyệt đối Design System trong `design.md` (Design tokens: `AppColors`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppTextStyles`, `appLightTheme`, `appDarkTheme`, `StatusBadge`, v.v.).
- **Workspace ảnh hưởng**: `fe/` (Flutter project).
- **Tham chiếu Backend**: `be/src/modules/auth/` và `be/src/modules/user/`.

---

## 2. Yêu cầu Gốc và Nguồn Tham Chiếu
- **Luồng màn hình**: `docs/screen.mmd`
- **Design guidelines**: `design.md`
- **Backend API endpoints & DTOs**:
  - `be/src/modules/auth/infra/controllers/auth.controller.ts`
  - `be/src/modules/auth/dtos/req.dto.ts`
  - `be/src/modules/auth/dtos/response.dto.ts`
  - `be/src/modules/user/domain/dtos/res.dto.ts`
  - `be/src/modules/user/domain/enums/role.enum.ts`

---

## 3. Kiến trúc Frontend Flutter

### 3.1 Dependencies bổ sung trong `fe/pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.2.0              # HTTP client kết nối NestJS backend
  provider: ^6.1.2          # State management nhẹ nhàng bằng ChangeNotifierProvider
  shared_preferences: ^2.2.2 # Lưu trữ token và session người dùng
  google_fonts: ^6.1.0      # Font Inter và JetBrains Mono theo design.md
```

### 3.2 Quản lý Định tuyến (Routing)
- Sử dụng **Named Routes** với `AppRoutes`:
  - `/role-select`: Màn hình khởi động chọn cổng (mặc định ban đầu nếu chưa đăng nhập)
  - `/reader/login`: Đăng nhập độc giả
  - `/staff/login`: Đăng nhập nhân viên
  - `/register`: Đăng ký tài khoản độc giả
  - `/verify-register`: Nhập OTP xác thực email độc giả
  - `/reg-success`: Thông báo đăng ký thành công
  - `/reader/forgot-password`: Quên mật khẩu độc giả
  - `/reader/otp`: Nhập OTP xác minh quên mật khẩu độc giả
  - `/reader/reset-password`: Đặt lại mật khẩu độc giả
  - `/staff/forgot-password`: Quên mật khẩu nhân viên
  - `/staff/otp`: Nhập OTP xác minh quên mật khẩu nhân viên
  - `/staff/reset-password`: Đặt lại mật khẩu nhân viên
  - `/reader/home`: Trang chủ Độc giả
  - `/staff/home`: Bảng điều khiển Nhân viên
- Cơ chế Route Guard / Auth Check:
  - Khi mở app (`main.dart`), `AuthProvider.checkAuth()` kiểm tra token hợp lệ trong `TokenStorage`.
  - Nếu đã có token và chưa hết hạn: điều hướng thẳng đến `/reader/home` (role `reader`) hoặc `/staff/home` (role `staff`/`admin`).
  - Nếu chưa đăng nhập: điều hướng tới `/role-select`.

### 3.3 Quản lý Trạng thái (State Management)
- Triển khai `AuthProvider extends ChangeNotifier`:
  - **State**:
    - `UserRes? currentUser`: thông tin người dùng (`userId`, `email`, `role`).
    - `String? accessToken`: JWT access token.
    - `String? refreshToken`: refresh token.
    - `bool isLoading`: trạng thái thực hiện API.
    - `String? errorMessage`: thông điệp lỗi trả về từ server / network.
    - `String? pendingEmail`: email đang trong luồng xác thực OTP / quên mật khẩu.
    - `String? pendingResetToken`: token tạm cho luồng reset mật khẩu.
  - **Actions**:
    - `Future<bool> login({required String username, required String password, required UserRole expectedRole})`
    - `Future<bool> register({required String username, required String email, required String password, String? displayName})`
    - `Future<bool> verifyEmail({required String email, required String code})`
    - `Future<bool> forgotPassword({required String email})`
    - `Future<bool> verifyResetOtp({required String email, required String code})`
    - `Future<bool> resetPassword({required String email, required String newPassword})`
    - `Future<void> logout()`
    - `Future<void> checkAuth()`

### 3.4 Quản lý Lưu trữ Token (Storage)
- Interface `TokenStorage`:
  - `saveTokens({required String accessToken, required String refreshToken})`
  - `getAccessToken(): Future<String?>`
  - `getRefreshToken(): Future<String?>`
  - `saveUser(UserRes user)`
  - `getUser(): Future<UserRes?>`
  - `clear()`
- Triển khai cụ thể: `SharedPreferencesTokenStorage` sử dụng package `shared_preferences`.

### 3.5 Tầng Mạng & HTTP Client (Network Layer)
- `ApiClient`:
  - `baseUrl`: Cấu hình qua hằng số `ApiConstants.baseUrl` (mặc định `http://localhost:3000` hoặc IP máy ảo Android `http://10.0.2.2:3000`).
  - Headers chuẩn: `Content-Type: application/json`, `Accept: application/json`.
  - Tự động gắn header `Authorization: Bearer <accessToken>` cho request yêu cầu xác thực.
  - Xử lý lỗi tập trung: Map HTTP status code 400, 401, 403, 404, 409, 500 thành `ApiException` với message rõ ràng chuẩn tiếng Việt theo `design.md`.
  - Xử lý Refresh Token tự động khi gặp 401 Unauthorized (gọi `POST /auth/refresh-token`).

---

## 4. Đặc tả Màn hình Chi tiết (UI Screens & Flow)

### 4.1 Màn hình 1: `RoleSelect` (Khởi động / Chọn cổng)
- **Đường dẫn route**: `/role-select`
- **Mục tiêu**: Phân tách luồng trải nghiệm cho Độc giả và Nhân viên thư viện.
- **Giao diện**:
  - Logo và tên hệ thống: "LibIO — Quản lý Thư viện".
  - Tiêu đề phụ: "Vui lòng chọn cổng đăng nhập của bạn".
  - 2 Thẻ Card chọn cổng (`AppCard` với viền hover):
    - Cổng Độc giả: Icon `Icons.menu_book_rounded`, Tiêu đề "Độc giả", Chú thích "Tra cứu tài liệu, mượn trả và quản lý tài khoản cá nhân". Nút Primary "Đăng nhập Độc giả" chuyển sang `/reader/login`.
    - Cổng Nhân viên: Icon `Icons.admin_panel_settings_rounded`, Tiêu đề "Thủ thư & Nhân viên", Chú thích "Quản lý kho sách, quầy check-in/out và nghiệp vụ thư viện". Nút Secondary "Đăng nhập Nhân viên" chuyển sang `/staff/login`.
  - Layout: `AuthLayout` căn giữa màn hình, giới hạn chiều rộng 540px.

### 4.2 Màn hình 2: `ReaderLogin` (Đăng nhập Độc giả)
- **Đường dẫn route**: `/reader/login`
- **Trường nhập liệu**:
  - `username`: Email hoặc tên đăng nhập (TextFormField, hint "Email hoặc tên đăng nhập", tiền tố Icon `Icons.person_outline`).
  - `password`: Mật khẩu (TextFormField, obscureText với nút toggle ẩn/hiện mắt, Icon `Icons.lock_outline`).
- **Hành động & Điều hướng**:
  - Nút Primary "Đăng nhập": Gọi `authProvider.login(expectedRole: UserRole.reader)`. Thành công chuyển sang `/reader/home`. Lỗi hiển thị `Alert inline` màu danger.
  - Link "Quên mật khẩu?": Chuyển sang `/reader/forgot-password`.
  - Link "Chưa có tài khoản? Đăng ký ngay": Chuyển sang `/register`.
  - Nút chuyển cổng phụ: "Bạn là thủ thư? Chuyển sang cổng Nhân viên" chuyển sang `/staff/login`.

### 4.3 Màn hình 3: `StaffLogin` (Đăng nhập Nhân viên)
- **Đường dẫn route**: `/staff/login`
- **Trường nhập liệu**:
  - `email`: Email nội bộ thư viện (TextFormField, hint "Email nội bộ (@thuvien.vn)", Icon `Icons.badge_outlined`).
  - `password`: Mật khẩu (TextFormField, obscureText có toggle, Icon `Icons.lock_outline`).
- **Hành động & Điều hướng**:
  - Nút Primary "Đăng nhập hệ thống": Gọi `authProvider.login(expectedRole: UserRole.staff)`. Thành công chuyển sang `/staff/home`. Nếu tài khoản là `reader` cố đăng nhập cổng staff, từ chối và báo lỗi phân quyền.
  - Link "Quên mật khẩu?": Chuyển sang `/staff/forgot-password`.
  - Nút chuyển cổng phụ: "Chuyển sang cổng Độc giả" chuyển sang `/reader/login`.
  - Ghi chú: Nhân viên không có nút tự đăng ký (tài khoản do quản trị viên cấp).

### 4.4 Màn hình 4: `Register` (Đăng ký Độc giả)
- **Đường dẫn route**: `/register`
- **Trường nhập liệu**:
  - `email`: Địa chỉ email nhận OTP (bắt buộc, định dạng email).
  - `username`: Tên đăng nhập (bắt buộc, không dấu/khoảng trắng).
  - `displayName`: Họ và tên hiển thị (tùy chọn).
  - `password`: Mật khẩu (bắt buộc, tối thiểu 6 ký tự).
  - `confirmPassword`: Xác nhận mật khẩu (bắt buộc trùng khớp).
- **Hành động & Điều hướng**:
  - Nút Primary "Đăng ký tài khoản": Gọi `authProvider.register(...)`. Thành công lưu `pendingEmail` và chuyển sang `/verify-register`.
  - Link "Đã có tài khoản? Đăng nhập": Quay về `/reader/login`.

### 4.5 Màn hình 5: `VerifyRegister` (Xác thực OTP Email Đăng ký)
- **Đường dẫn route**: `/verify-register`
- **Giao diện**:
  - Icon thư `Icons.mark_email_read_outlined`.
  - Thông báo: "Mã xác thực đã được gửi đến email: `<pendingEmail>`".
  - Ô nhập OTP: 6 ký tự số, dùng font `AppTextStyles.mono`, căn giữa, tự động focus.
  - Bộ đếm ngược gửi lại mã: 60s đếm ngược, sau 60s cho phép bấm "Gửi lại mã OTP".
- **Hành động & Điều hướng**:
  - Nút Primary "Xác thực": Gọi `authProvider.verifyEmail(email, code)`. Thành công chuyển sang `/reg-success`.
  - Link "Đổi email khác": Quay lại `/register`.

### 4.6 Màn hình 6: `RegSuccess` (Thông báo Đăng ký Thành công)
- **Đường dẫn route**: `/reg-success`
- **Giao diện**:
  - Icon thành công lớn màu `AppColors.success`.
  - Tiêu đề: "Đăng ký tài khoản thành công!".
  - Nội dung: "Tài khoản độc giả của bạn đã sẵn sàng sử dụng. Hãy đăng nhập để bắt đầu tra cứu và mượn tài liệu."
  - Nút Primary "Đăng nhập ngay": Chuyển về `/reader/login` (dùng `Navigator.pushNamedAndRemoveUntil`).

### 4.7 Màn hình 7: `ForgotPwdReader` (Quên mật khẩu Độc giả)
- **Đường dẫn route**: `/reader/forgot-password`
- **Trường nhập liệu**:
  - `identifier`: Email hoặc Số điện thoại độc giả.
- **Hành động & Điều hướng**:
  - Nút Primary "Tiếp tục": Gọi API `POST /auth/forgot-password` (hoặc fallback), chuyển sang `/reader/otp`.
  - Nút Secondary / Link "Quay lại đăng nhập": Quay về `/reader/login`.

### 4.8 Màn hình 8: `OtpReader` (Nhập OTP Quên mật khẩu Độc giả)
- **Đường dẫn route**: `/reader/otp`
- **Trường nhập liệu**:
  - Ô nhập OTP 6 số (chữ số, `mono`, căn giữa).
- **Hành động & Điều hướng**:
  - Nút Primary "Xác minh OTP": Kiểm tra mã OTP (client fallback / API), thành công chuyển sang `/reader/reset-password`.
  - Link "Gửi lại mã OTP" và "Quay lại".

### 4.9 Màn hình 9: `ResetPwdReader` (Đặt lại Mật khẩu Độc giả)
- **Đường dẫn route**: `/reader/reset-password`
- **Trường nhập liệu**:
  - `newPassword`: Mật khẩu mới (tối thiểu 6 ký tự).
  - `confirmPassword`: Xác nhận mật khẩu mới.
- **Hành động & Điều hướng**:
  - Nút Primary "Cập nhật mật khẩu": Gọi service cập nhật mật khẩu, hiển thị thông báo thành công qua `SnackBar` floating màu `AppColors.success`.
  - Điều hướng: Chuyển về `/reader/login`.

### 4.10 Màn hình 10: `ForgotPwdStaff` (Quên mật khẩu Nhân viên)
- **Đường dẫn route**: `/staff/forgot-password`
- **Trường nhập liệu**:
  - `email`: Email nội bộ nhân viên (@thuvien.vn).
- **Hành động & Điều hướng**:
  - Nút Primary "Gửi mã xác minh": Gọi API `POST /auth/forgot-password`, chuyển sang `/staff/otp`.
  - Nút Quay lại `/staff/login`.

### 4.11 Màn hình 11: `OtpStaff` (Nhập OTP Quên mật khẩu Nhân viên)
- **Đường dẫn route**: `/staff/otp`
- **Trường nhập liệu**:
  - Ô nhập OTP 6 số.
- **Hành động & Điều hướng**:
  - Nút Primary "Xác thực": Chuyển sang `/staff/reset-password`.
  - Nút Quay lại `/staff/login`.

### 4.12 Màn hình 12: `ResetPwdStaff` (Đặt lại Mật khẩu Nhân viên)
- **Đường dẫn route**: `/staff/reset-password`
- **Trường nhập liệu**:
  - `newPassword`: Mật khẩu mới.
  - `confirmPassword`: Xác nhận mật khẩu mới.
- **Hành động & Điều hướng**:
  - Nút Primary "Cập nhật mật khẩu": Cập nhật thành công báo `SnackBar` success.
  - Điều hướng: Chuyển về `/staff/login`.

### 4.13 Màn hình 13: `ReaderHome` (Trang chủ Độc giả)
- **Đường dẫn route**: `/reader/home`
- **Giao diện**:
  - AppBar với logo LibIO và badge `StatusBadge(label: 'Độc giả', color: AppColors.info)`.
  - Thông tin người dùng đăng nhập: Email, Mã bạn đọc (`userId`), Quyền hạn.
  - Card chào mừng và các phím tắt nhanh: "Tra cứu sách", "Lịch sử mượn trả", "Đổi mật khẩu".
  - Nút OutlinedButton "Đăng xuất": Xóa token trong storage, xóa state trong `AuthProvider`, điều hướng về `/role-select`.

### 4.14 Màn hình 14: `StaffHome` (Bảng điều khiển Nhân viên)
- **Đường dẫn route**: `/staff/home`
- **Giao diện**:
  - AppBar với badge `StatusBadge(label: 'Thủ thư / Nhân viên', color: AppColors.success)`.
  - Thẻ thông tin tài khoản nhân viên: Email nội bộ, Vai trò (`staff` hoặc `admin`).
  - Card trạng thái quầy thư viện (Check-in / Check-out phím tắt nhanh).
  - Nút OutlinedButton "Đăng xuất": Xóa token trong storage, xóa state, điều hướng về `/role-select`.

---

## 5. Tích hợp Backend API & Cơ chế Mock/Fallback

### 5.1 Ma trận Ánh xạ API Backend

| Thao tác UI | Endpoint Backend | HTTP Method | DTO Gửi đi (Request) | DTO Nhận về (Response) |
|---|---|---|---|---|
| Đăng nhập | `/auth/login` | POST | `LoginReq { username, password }` | `AuthRes { accessToken, refreshToken, user: UserRes }` |
| Đăng ký độc giả | `/auth/register` | POST | `RegisterReq { username, email, password, displayName }` | `RegisterPendingRes { message, email }` |
| Xác thực OTP email | `/auth/verify-email` | POST | `VerifyEmailReq { email, code }` | `UserRes { userId, email, role }` |
| Yêu cầu quên mật khẩu | `/auth/forgot-password` | POST | `ForgotPasswordReq { email }` | `{ message: string }` |
| Đổi mật khẩu đăng nhập | `/auth/update-password` | POST (Bearer) | `UpdatePasswordReq { oldPassword, newPassword }` | `{ message: string }` |
| Làm mới Access Token | `/auth/refresh-token` | POST | `RefreshTokenReq { refreshToken }` | `AuthRes` |

### 5.2 Xử lý Đặc biệt & Chiến lược Mock/Fallback
1. **Username trong LoginReq**: Backend NestJS hiện tại kiểm tra `userRepo.findOne({ where: { email: req.username } })`. Vì vậy trên UI, trường đăng nhập hỗ trợ người dùng nhập email (hoặc username nếu sau này BE map thêm). UI placeholder ghi rõ "Email tài khoản".
2. **Luồng Quên mật khẩu & Đặt lại mật khẩu**:
   - Backend hiện tại đã có `POST /auth/forgot-password` (ghi log, chưa bắn email thực tế).
   - Backend **chưa có** public endpoint `POST /auth/verify-reset-code` và `POST /auth/reset-password` unauthenticated (BE chỉ mới có `/auth/update-password` yêu cầu JWT Bearer + `oldPassword`).
   - **Giải pháp Mock/Fallback trong `AuthApiService`**:
     - `forgotPassword(email)`: Gọi thật `POST /auth/forgot-password`. Nếu server phản hồi 200, tiếp tục. Nếu gặp lỗi kết nối dev/offline, bật cờ fallback cho phép tiếp tục flow UI.
     - `verifyResetOtp(email, code)`: Triển khai kiểm tra cục bộ (ví dụ: chấp nhận mã 6 số bất kỳ hoặc mã mặc định `'123456'` / dev OTP).
     - `resetPassword(email, newPassword)`: Giả lập thành công (mock delay 500ms) để UI hoàn tất chuyển hướng.
     - Đặt comment đánh dấu: `// ponytail: switch to actual POST /auth/reset-password endpoint once backend implements unauthenticated OTP reset password`.

---

## 6. Thiết kế Design System Tokens (`lib/core/theme/`)

Các file token sẽ triển khai nguyên bản theo `design.md`:
1. `lib/core/theme/app_colors.dart`:
   - Charcoal tokens: `charcoal900` (`0xFF14161A`) đến `charcoal400` (`0xFF6B717C`).
   - Neutral tokens: `neutral50` (`0xFFF8F9FA`) đến `neutral500` (`0xFF8A919B`), `white` (`0xFFFFFFFF`).
   - Accent tokens: `accent100`, `accent500` (`0xFFE0A526`), `accent600`.
   - Semantic tokens: `success`, `successLight`, `warning`, `warningLight`, `danger`, `dangerLight`, `info`, `infoLight`, `reserved`, `reservedLight`, `textMutedDark`.
2. `lib/core/theme/app_spacing.dart`:
   - Hằng số `s1` (4) đến `s7` (48).
   - Helpers `EdgeInsets`: `p1` đến `p6`.
3. `lib/core/theme/app_radius.dart`:
   - `sm` (4), `md` (8), `lg` (12), `full` (9999).
   - `brSm`, `brMd`, `brLg`, `brFull`.
4. `lib/core/theme/app_shadows.dart`:
   - `sm`, `md`, `lg` box shadows.
5. `lib/core/theme/app_text_styles.dart`:
   - Cỡ chữ, line-height tỉ lệ chuẩn Flutter (`height = lineHeight / fontSize`).
   - `display` (32/1.25, w700), `h1` (24/1.33, w700), `h2` (20/1.4, w600), `h3` (16/1.5, w600), `body` (14/1.57, w400), `bodySm` (13/1.54, w400), `caption` (12/1.33, w500), `mono` (14/1.43, w500).
6. `lib/core/theme/app_theme.dart`:
   - Hàm `appLightTheme` và `appDarkTheme` đầy đủ cấu hình Material 3, `ColorScheme`, `CardThemeData`, `DividerThemeData`, `InputDecorationTheme`.
7. `lib/shared/widgets/`:
   - `status_badge.dart`: Badge dạng pill cao 24px, icon 14px, text caption, màu semantic theo bảng mục 2.5 trong `design.md`.
   - `app_button.dart`: Hỗ trợ 4 biến thể (Primary, Secondary, Ghost, Danger), hỗ trợ loading spinner, disabled state, bo góc `AppRadius.brMd`.
   - `app_text_field.dart`: TextFormField chuẩn hóa viền `neutral300`, focus viền `accent500`, error viền `danger`, hỗ trợ icon tiền tố và hậu tố toggle mật khẩu.
   - `auth_layout.dart`: Bố cục bao ngoài cho các trang auth với card căn giữa, `ConstrainedBox(maxWidth: 480)`, responsive cho mobile & desktop.

---

## 7. Cấu trúc Thư mục và Danh sách File Cần Tạo / Sửa

```
fe/
├── pubspec.yaml                                         # [EDIT] Thêm dependencies http, provider, shared_preferences, google_fonts
└── lib/
    ├── main.dart                                        # [EDIT] Khởi tạo App, Provider, MultiProvider, MaterialApp với AppRoutes và theme
    ├── core/
    │   ├── constants/
    │   │   ├── api_constants.dart                       # [NEW] Cấu hình URL backend NestJS và timeout
    │   │   └── app_routes.dart                          # [NEW] Định nghĩa các chuỗi named routes
    │   ├── network/
    │   │   ├── api_client.dart                          # [NEW] HTTP client bọc base URL, token header, handle HTTP status
    │   │   └── api_exception.dart                       # [NEW] Định nghĩa lớp ngoại lệ ApiException thân thiện người dùng
    │   ├── storage/
    │   │   └── token_storage.dart                       # [NEW] Interface và SharedPreferencesTokenStorage
    │   └── theme/
    │       ├── app_colors.dart                          # [NEW] Bảng màu chuẩn từ design.md
    │       ├── app_spacing.dart                         # [NEW] Thang spacing s1..s7 và p1..p6
    │       ├── app_radius.dart                          # [NEW] Thang bo góc brSm, brMd, brLg, brFull
    │       ├── app_shadows.dart                         # [NEW] Đổ bóng sm, md, lg
    │       ├── app_text_styles.dart                     # [NEW] Thang Typography Inter & JetBrains Mono
    │       └── app_theme.dart                           # [NEW] appLightTheme & appDarkTheme
    ├── data/
    │   ├── models/
    │   │   ├── role.dart                                # [NEW] Enum UserRole (reader, staff, admin)
    │   │   ├── user_model.dart                          # [NEW] DTO UserRes { userId, email, role }
    │   │   ├── auth_response.dart                       # [NEW] DTO AuthRes { accessToken, refreshToken, user }
    │   │   ├── register_pending_response.dart           # [NEW] DTO RegisterPendingRes { message, email }
    │   │   ├── login_request.dart                       # [NEW] DTO LoginReq { username, password }
    │   │   ├── register_request.dart                    # [NEW] DTO RegisterReq { username, email, password, displayName }
    │   │   ├── verify_email_request.dart                # [NEW] DTO VerifyEmailReq { email, code }
    │   │   ├── forgot_password_request.dart             # [NEW] DTO ForgotPasswordReq { email }
    │   │   └── update_password_request.dart             # [NEW] DTO UpdatePasswordReq { oldPassword, newPassword }
    │   └── services/
    │       └── auth_api_service.dart                    # [NEW] Service gọi API backend NestJS + Fallback logic
    ├── providers/
    │   └── auth_provider.dart                           # [NEW] ChangeNotifier quản lý toàn bộ trạng thái Auth
    ├── shared/
    │   └── widgets/
    │       ├── status_badge.dart                        # [NEW] StatusBadge widget chuẩn design.md mục 6.3
    │       ├── app_button.dart                          # [NEW] AppButton tùy biến Primary, Secondary, Ghost, Danger
    │       ├── app_text_field.dart                      # [NEW] AppTextField chuẩn styling mục 6.2
    │       ├── app_card.dart                            # [NEW] Card chuẩn viền neutral200 bo góc brLg
    │       └── auth_layout.dart                         # [NEW] Layout wrapper căn giữa cho các trang Auth (maxWidth 480px)
    └── features/
        ├── auth/
        │   └── screens/
        │       ├── role_select_screen.dart              # [NEW] Màn hình 1: Chọn cổng Độc giả vs Nhân viên
        │       ├── reader_login_screen.dart             # [NEW] Màn hình 2: Đăng nhập Độc giả
        │       ├── staff_login_screen.dart              # [NEW] Màn hình 3: Đăng nhập Nhân viên
        │       ├── register_screen.dart                 # [NEW] Màn hình 4: Đăng ký tài khoản Độc giả
        │       ├── verify_register_screen.dart          # [NEW] Màn hình 5: Xác thực OTP Email Đăng ký
        │       ├── reg_success_screen.dart              # [NEW] Màn hình 6: Thông báo Đăng ký thành công
        │       ├── forgot_pwd_reader_screen.dart        # [NEW] Màn hình 7: Quên mật khẩu Độc giả
        │       ├── otp_reader_screen.dart               # [NEW] Màn hình 8: Nhập OTP Độc giả
        │       ├── reset_pwd_reader_screen.dart         # [NEW] Màn hình 9: Đặt lại mật khẩu Độc giả
        │       ├── forgot_pwd_staff_screen.dart         # [NEW] Màn hình 10: Quên mật khẩu Nhân viên
        │       ├── otp_staff_screen.dart                # [NEW] Màn hình 11: Nhập OTP Nhân viên
        │       └── reset_pwd_staff_screen.dart          # [NEW] Màn hình 12: Đặt lại mật khẩu Nhân viên
        └── home/
            └── screens/
                ├── reader_home_screen.dart              # [NEW] Màn hình 13: Trang chủ Độc giả sau đăng nhập
                └── staff_home_screen.dart               # [NEW] Màn hình 14: Bảng điều khiển Nhân viên sau đăng nhập
```

---

## 8. Thứ tự Triển khai (Dành cho Executor)

1. **Bước 1: Cấu hình dependencies (`pubspec.yaml`)**
   - Thêm `http`, `provider`, `shared_preferences`, `google_fonts`.
   - Chạy `flutter pub get` để tải các gói.
2. **Bước 2: Xây dựng Tầng Design System Tokens (`lib/core/theme/`)**
   - Tạo `app_colors.dart`, `app_spacing.dart`, `app_radius.dart`, `app_shadows.dart`, `app_text_styles.dart`.
   - Tạo `app_theme.dart` với `appLightTheme` và `appDarkTheme`.
3. **Bước 3: Xây dựng Shared Components (`lib/shared/widgets/`)**
   - Tạo `status_badge.dart`, `app_button.dart`, `app_text_field.dart`, `app_card.dart`, `auth_layout.dart`.
4. **Bước 4: Xây dựng Data Models, Storage & Tầng Mạng (`lib/data/`, `lib/core/storage/`, `lib/core/network/`)**
   - Tạo `Role` enum và các DTOs (Request/Response).
   - Tạo `TokenStorage` lưu trữ `accessToken`, `refreshToken`, thông tin user.
   - Tạo `ApiClient` và `AuthApiService` bọc các API `/auth/*` với mock/fallback linh hoạt.
5. **Bước 5: Xây dựng State Management (`lib/providers/auth_provider.dart`)**
   - Xử lý các luồng gọi API, cập nhật `isLoading`, `errorMessage`, `currentUser`, lưu session.
6. **Bước 6: Xây dựng Routing và Khởi chạy App (`lib/core/constants/app_routes.dart`, `lib/main.dart`)**
   - Khởi tạo `MultiProvider`, `MaterialApp(initialRoute: ..., routes: ...)`.
7. **Bước 7: Triển khai 14 Màn hình Giao diện (`lib/features/auth/screens/` & `lib/features/home/screens/`)**
   - Triển khai theo đúng thứ tự flow:
     - `RoleSelectScreen` -> `ReaderLoginScreen` & `StaffLoginScreen`.
     - `RegisterScreen` -> `VerifyRegisterScreen` -> `RegSuccessScreen`.
     - Luồng quên mật khẩu Độc giả: `ForgotPwdReaderScreen` -> `OtpReaderScreen` -> `ResetPwdReaderScreen`.
     - Luồng quên mật khẩu Nhân viên: `ForgotPwdStaffScreen` -> `OtpStaffScreen` -> `ResetPwdStaffScreen`.
     - Màn hình đích: `ReaderHomeScreen` và `StaffHomeScreen`.
8. **Bước 8: Kiểm tra Lints & Build Clean**
   - Chạy `flutter analyze` đảm bảo không có warning, code chuẩn convention Dart.

---

## 9. Tiêu chí Kiểm thử & Nghiệm thu (Dành cho Auditor)

### 9.1 Kiểm thử Luồng Điều hướng (Navigation Flow)
- [ ] Mở ứng dụng lần đầu vào đúng `RoleSelectScreen`.
- [ ] Từ `RoleSelectScreen`, bấm "Độc giả" chuyển sang `ReaderLoginScreen`, bấm "Nhân viên" chuyển sang `StaffLoginScreen`.
- [ ] Nút đổi cổng qua lại giữa `ReaderLoginScreen` và `StaffLoginScreen` hoạt động chuẩn.
- [ ] Luồng Đăng ký Độc giả: `ReaderLogin` -> `Register` -> `VerifyRegister` -> `RegSuccess` -> quay về `ReaderLogin`.
- [ ] Luồng Quên MK Độc giả: `ReaderLogin` -> `ForgotPwdReader` -> `OtpReader` -> `ResetPwdReader` -> quay về `ReaderLogin`.
- [ ] Luồng Quên MK Nhân viên: `StaffLogin` -> `ForgotPwdStaff` -> `OtpStaff` -> `ResetPwdStaff` -> quay về `StaffLogin`.
- [ ] Đăng nhập thành công tài khoản Độc giả chuyển vào `ReaderHomeScreen`.
- [ ] Đăng nhập thành công tài khoản Nhân viên chuyển vào `StaffHomeScreen`.
- [ ] Nút "Đăng xuất" ở `ReaderHomeScreen` và `StaffHomeScreen` xóa token và quay về `RoleSelectScreen`.

### 9.2 Kiểm thử Phân quyền (Role Isolation)
- [ ] Tài khoản có role `reader` khi cố đăng nhập ở cổng `StaffLogin` phải bị chặn và hiển thị lỗi: "Tài khoản không có quyền truy cập cổng Nhân viên".
- [ ] Tài khoản có role `staff` hoặc `admin` đăng nhập thành công ở cổng `StaffLogin`.

### 9.3 Kiểm thử Giao diện & Design System
- [ ] Không có màu sắc, khoảng cách, bo góc nào bị hard-code ngoài tokens `AppColors`, `AppSpacing`, `AppRadius`, `AppTextStyles`.
- [ ] `StatusBadge` hiển thị đúng màu và icon theo vai trò (`reader`: info, `staff`: success).
- [ ] Nút bấm có đầy đủ trạng thái: hover, focus, disabled khi input trống/không hợp lệ, loading spinner khi đang gọi API.
- [ ] Layout căn giữa `maxWidth: 480` co giãn tốt trên cả Mobile lẫn Desktop/Tablet.
- [ ] Ô nhập mật khẩu có nút bật/tắt ẩn hiện mật khẩu hoạt động trơn tru.

### 9.4 Kiểm thử Tích hợp API Backend
- [ ] `POST /auth/login` gửi đúng body `{ username, password }`, lưu được `accessToken` và `refreshToken`.
- [ ] `POST /auth/register` gửi đúng `{ username, email, password, displayName }`, nhận `RegisterPendingRes`.
- [ ] `POST /auth/verify-email` gửi `{ email, code }` 6 số, nhận `UserRes` thành công.
- [ ] Luồng Quên mật khẩu hoạt động thông suốt cả khi BE chưa có đầy đủ unauthenticated OTP reset endpoint nhờ tầng fallback.
- [ ] Lỗi từ backend (400, 401, 409) hiển thị message tiếng Việt thân thiện trong Alert hoặc SnackBar.

### 9.5 Chất lượng Mã nguồn
- [ ] Chạy lệnh `flutter analyze` đạt 0 error, 0 warning.
- [ ] Tên file theo chuẩn `snake_case`, tên class widget theo chuẩn `PascalCase`.
