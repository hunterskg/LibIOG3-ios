# Design Guidelines — Hệ thống quản lý Check-in/Check-out Thư viện

Tài liệu này là nguồn tham chiếu duy nhất (single source of truth) cho giao diện Flutter. Mọi màu sắc, khoảng cách, font chữ và widget phải dùng **token / theme extension** được định nghĩa ở đây, không hard-code giá trị.

## 1. Nguyên tắc thiết kế

1. **Rõ ràng trước, đẹp sau**: thủ thư thao tác liên tục, ưu tiên đọc nhanh và bấm đúng.
2. **Tối giản**: nền trung tính, màu chủ đạo than đen, màu sắc chỉ dùng khi mang ý nghĩa (trạng thái, hành động).
3. **Nhất quán**: cùng một việc phải trông và hoạt động giống nhau ở mọi màn hình.
4. **Không chỉ dựa vào màu**: trạng thái luôn kèm icon hoặc nhãn chữ.
5. **Thao tác nhanh**: hỗ trợ bàn phím (`Shortcuts` / `Actions` / `FocusNode`) và máy quét mã vạch ở các màn hình check-in/out.

## 2. Màu sắc

### 2.1 Màu chủ đạo (Charcoal)

| Token (Dart) | Hex | Giá trị `Color` | Dùng cho |
|---|---|---|---|
| `AppColors.charcoal900` | `#14161A` | `Color(0xFF14161A)` | NavigationRail, AppBar, nền dark mode |
| `AppColors.charcoal800` | `#1F2227` | `Color(0xFF1F2227)` | **Primary**: ElevatedButton, thanh điều hướng |
| `AppColors.charcoal700` | `#2B2F36` | `Color(0xFF2B2F36)` | Hover primary, Card dark mode |
| `AppColors.charcoal600` | `#3A3F48` | `Color(0xFF3A3F48)` | Divider, Border dark mode |
| `AppColors.charcoal500` | `#4F555F` | `Color(0xFF4F555F)` | Icon phụ, text phụ |
| `AppColors.charcoal400` | `#6B717C` | `Color(0xFF6B717C)` | HintText, disabled |

### 2.2 Trung tính

| Token (Dart) | Hex | Giá trị `Color` | Dùng cho |
|---|---|---|---|
| `AppColors.neutral50` | `#F8F9FA` | `Color(0xFFF8F9FA)` | `scaffoldBackgroundColor` (light) |
| `AppColors.neutral100` | `#F1F3F5` | `Color(0xFFF1F3F5)` | DataTable header, hàng xen kẽ |
| `AppColors.neutral200` | `#E3E6EA` | `Color(0xFFE3E6EA)` | `DividerTheme`, Border |
| `AppColors.neutral300` | `#CDD2D8` | `Color(0xFFCDD2D8)` | InputDecoration enabledBorder |
| `AppColors.neutral500` | `#8A919B` | `Color(0xFF8A919B)` | Text phụ |
| `AppColors.white` | `#FFFFFF` | `Color(0xFFFFFFFF)` | Card, Dialog surface |

### 2.3 Accent (vàng hổ phách)

| Token (Dart) | Hex | Giá trị `Color` | Dùng cho |
|---|---|---|---|
| `AppColors.accent100` | `#FBF0D4` | `Color(0xFFFBF0D4)` | Nền highlight nhẹ |
| `AppColors.accent500` | `#E0A526` | `Color(0xFFE0A526)` | Điểm nhấn, badge, focus ring |
| `AppColors.accent600` | `#C28A12` | `Color(0xFFC28A12)` | Hover |

### 2.4 Ngữ nghĩa

| Trạng thái | Màu chính | Nền nhạt |
|---|---|---|
| Success | `AppColors.success` (`0xFF2E9E6B`) | `AppColors.successLight` (`0xFFE4F5ED`) |
| Warning | `AppColors.warning` (`0xFFE08A1E`) | `AppColors.warningLight` (`0xFFFCEFDC`) |
| Danger | `AppColors.danger` (`0xFFD64545`) | `AppColors.dangerLight` (`0xFFFBE7E7`) |
| Info | `AppColors.info` (`0xFF3B82C4`) | `AppColors.infoLight` (`0xFFE3EFF9`) |

### 2.5 Màu theo trạng thái nghiệp vụ

| Trạng thái | Nhãn | Màu | Icon (`Icons` / `LucideIcons`) |
|---|---|---|---|
| Đã trả / Check-in | `Đã trả` | `0xFF2E9E6B` | `Icons.check_circle_outline` |
| Đang mượn / Check-out | `Đang mượn` | `0xFF3B82C4` | `Icons.menu_book_outlined` |
| Sắp đến hạn | `Sắp đến hạn` | `0xFFE08A1E` | `Icons.access_time` |
| Quá hạn | `Quá hạn` | `0xFFD64545` | `Icons.warning_amber_rounded` |
| Đã đặt trước | `Đã đặt trước` | `0xFF7C5CBF` | `Icons.bookmark_border` |
| Không khả dụng / Mất | `Không khả dụng` | `0xFF6B717C` | `Icons.block` |

### 2.6 Màu chữ

| Ngữ cảnh | Chính | Phụ |
|---|---|---|
| Nền sáng | `AppColors.charcoal900` (`0xFF14161A`) | `AppColors.charcoal500` (`0xFF4F555F`) |
| Nền tối | `AppColors.neutral100` (`0xFFF1F3F5`) | `Color(0xFFA7ADB6)` |

### 2.7 Quy tắc dùng màu

- Tỷ lệ gợi ý: **60%** neutral, **30%** charcoal, **10%** accent + semantic.
- Tương phản chữ/nền tối thiểu **4.5:1** (WCAG AA).
- Mỗi màn hình chỉ có **một** nút primary (`ElevatedButton`) nổi bật.
- Màu đỏ chỉ dành cho lỗi, quá hạn, hành động phá hủy.

## 3. Design tokens (Flutter / Dart)

### 3.1 AppColors

```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // Charcoal
  static const charcoal900 = Color(0xFF14161A);
  static const charcoal800 = Color(0xFF1F2227);
  static const charcoal700 = Color(0xFF2B2F36);
  static const charcoal600 = Color(0xFF3A3F48);
  static const charcoal500 = Color(0xFF4F555F);
  static const charcoal400 = Color(0xFF6B717C);

  // Neutral
  static const neutral50 = Color(0xFFF8F9FA);
  static const neutral100 = Color(0xFFF1F3F5);
  static const neutral200 = Color(0xFFE3E6EA);
  static const neutral300 = Color(0xFFCDD2D8);
  static const neutral500 = Color(0xFF8A919B);
  static const white = Color(0xFFFFFFFF);

  // Accent
  static const accent100 = Color(0xFFFBF0D4);
  static const accent500 = Color(0xFFE0A526);
  static const accent600 = Color(0xFFC28A12);

  // Semantic
  static const success = Color(0xFF2E9E6B);
  static const successLight = Color(0xFFE4F5ED);
  static const warning = Color(0xFFE08A1E);
  static const warningLight = Color(0xFFFCEFDC);
  static const danger = Color(0xFFD64545);
  static const dangerLight = Color(0xFFFBE7E7);
  static const info = Color(0xFF3B82C4);
  static const infoLight = Color(0xFFE3EFF9);
  static const reserved = Color(0xFF7C5CBF);
  static const reservedLight = Color(0xFFF0EBF8);

  // Dark text
  static const textMutedDark = Color(0xFFA7ADB6);
}
```

### 3.2 AppSpacing, AppRadius, AppShadows

```dart
import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 24;
  static const double s6 = 32;
  static const double s7 = 48;

  // EdgeInsets helpers
  static const p1 = EdgeInsets.all(s1);
  static const p2 = EdgeInsets.all(s2);
  static const p3 = EdgeInsets.all(s3);
  static const p4 = EdgeInsets.all(s4);
  static const p5 = EdgeInsets.all(s5);
  static const p6 = EdgeInsets.all(s6);
}

abstract final class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double full = 9999;

  static const brSm = BorderRadius.all(Radius.circular(sm));
  static const brMd = BorderRadius.all(Radius.circular(md));
  static const brLg = BorderRadius.all(Radius.circular(lg));
  static const brFull = BorderRadius.all(Radius.circular(full));
}

abstract final class AppShadows {
  static const sm = [
    BoxShadow(color: Color(0x0F14161A), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const md = [
    BoxShadow(color: Color(0x1A14161A), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const lg = [
    BoxShadow(color: Color(0x2914161A), blurRadius: 32, offset: Offset(0, 12)),
  ];
}
```

### 3.3 ThemeData (Light & Dark)

```dart
import 'package:flutter/material.dart';

ThemeData get appLightTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.neutral50,
  colorScheme: const ColorScheme.light(
    primary: AppColors.charcoal800,
    onPrimary: AppColors.white,
    secondary: AppColors.accent500,
    surface: AppColors.white,
    onSurface: AppColors.charcoal900,
    error: AppColors.danger,
    outline: AppColors.neutral200,
  ),
  cardTheme: const CardThemeData(
    color: AppColors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: AppColors.neutral200),
      borderRadius: AppRadius.brLg,
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.neutral200,
    thickness: 1,
    space: 1,
  ),
);

ThemeData get appDarkTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.charcoal900,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.accent500,
    onPrimary: AppColors.charcoal900,
    secondary: AppColors.accent600,
    surface: AppColors.charcoal800,
    onSurface: AppColors.neutral100,
    error: AppColors.danger,
    outline: AppColors.charcoal600,
  ),
  cardTheme: const CardThemeData(
    color: AppColors.charcoal800,
    elevation: 0,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: AppColors.charcoal600),
      borderRadius: AppRadius.brLg,
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.charcoal600,
    thickness: 1,
    space: 1,
  ),
);
```

## 4. Typography

| Vai trò | Font Family | Ghi chú |
|---|---|---|
| UI chính | `Inter`, fallback `sans-serif` | Hỗ trợ đầy đủ tiếng Việt (dùng `google_fonts` hoặc bundle asset) |
| Mã sách, barcode, ID | `JetBrains Mono`, fallback `monospace` | Dễ phân biệt `0/O`, `1/l/I` |

### 4.1 Thang TextStyle (TextTheme)

| Token (Dart) | Cỡ / Height | Weight | Dùng cho |
|---|---|---|---|
| `AppTextStyles.display` | 32 / 1.25 (40px) | `FontWeight.w700` | Tiêu đề trang chủ, số liệu lớn |
| `AppTextStyles.h1` | 24 / 1.33 (32px) | `FontWeight.w700` | Tiêu đề trang (`AppBar.title`) |
| `AppTextStyles.h2` | 20 / 1.40 (28px) | `FontWeight.w600` | Tiêu đề section |
| `AppTextStyles.h3` | 16 / 1.50 (24px) | `FontWeight.w600` | Tiêu đề Card |
| `AppTextStyles.body` | 14 / 1.57 (22px) | `FontWeight.w400` | Nội dung chính |
| `AppTextStyles.bodySm` | 13 / 1.54 (20px) | `FontWeight.w400` | Text phụ, ô DataTable |
| `AppTextStyles.caption` | 12 / 1.33 (16px) | `FontWeight.w500` | Nhãn, badge, chú thích |
| `AppTextStyles.mono` | 14 / 1.43 (20px) | `FontWeight.w500` | Barcode, mã bạn đọc, ISBN |

Quy tắc:
- `height` trong Flutter là tỉ lệ `lineHeight / fontSize` (VD: `40 / 32 = 1.25`).
- Không dùng quá 3 cỡ chữ trên một Card/khối nội dung.
- Không viết hoa toàn bộ (`toUpperCase()`) trừ mã barcode và badge viết tắt.

## 5. Layout và khoảng cách

- Dùng thang **4px**; chỉ dùng các hằng số `AppSpacing.s*`.
- Bố cục chính cho Desktop/Tablet:
  - `NavigationRail` (width 240px, khi thu gọn `extended: false` là 72px).
  - Top `AppBar` (height 56px).
  - Vùng nội dung: `Padding(padding: AppSpacing.p5)` (24px).
  - Trang dạng đọc: bọc trong `ConstrainedBox(constraints: BoxConstraints(maxWidth: 1280))`.
- Khoảng cách giữa các Card: `SizedBox(height: AppSpacing.s4)` (16px); giữa các section: `SizedBox(height: AppSpacing.s6)` (32px).
- Breakpoints Flutter (`MediaQuery.sizeOf(context).width` hoặc `LayoutBuilder`):
  - `sm`: `< 640` (Mobile)
  - `md`: `640 - 1023` (Tablet dọc)
  - `lg`: `1024 - 1279` (Tablet ngang / Desktop nhỏ)
  - `xl`: `>= 1280` (Desktop chuẩn cho quầy thư viện)
- Màn hình quầy check-in/out ưu tiên tối ưu cho **Desktop (Windows/macOS/Linux) và Tablet ngang (>= 1024px)**.

## 6. Component (Widgets)

### 6.1 Button

| Biến thể | Widget | Style | Dùng khi |
|---|---|---|---|
| Primary | `ElevatedButton` | nền `charcoal800`, chữ `white` | Hành động chính (Check-in, Check-out, Lưu) |
| Secondary | `OutlinedButton` | viền `neutral300`, chữ `charcoal900` | Hành động phụ |
| Ghost / Tertiary | `TextButton` | trong suốt, chữ `charcoal500` | Hành động ít quan trọng |
| Danger | `ElevatedButton` | nền `danger`, chữ `white` | Xóa, hủy, đánh dấu mất |

- Chiều cao nút:
  - `sm 32`: `padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6)`
  - `md 40` (mặc định): `padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10)`
  - `lg 48` (quầy check-in/out): `padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14)`
- Bo góc: `shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd)`.
- Trạng thái:
  - `onPressed: null` cho disabled (Flutter tự xử lý opacity).
  - Loading: bọc trong nút một `SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: ...))` thay cho `Icon`, giữ nguyên `width` tối thiểu để nút không bị co giật.

### 6.2 Input / Form (`TextFormField`, `TextField`)

- Chiều cao ô nhập: `contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)` (tương đương 40px).
- Viền mặc định: `OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: AppColors.neutral300))`.
- Focus: `focusedBorder` viền 2px `AppColors.accent500`.
- Lỗi: `errorBorder` viền `AppColors.danger`, `errorStyle` dùng `AppTextStyles.caption` màu `danger`.
- Label: đặt trong `InputDecoration(labelText: ...)` hoặc `Text` bên ngoài với `AppTextStyles.bodySm` + `FontWeight.w500`, bắt buộc đánh dấu `*`.
- **Ô quét mã vạch**:
  - Dùng `FocusNode` gán `autofocus: true`.
  - Font `AppTextStyles.mono`.
  - Bắt sự kiện `onSubmitted` để kích hoạt quét ngay, không chờ bấm nút.

### 6.3 Badge trạng thái (`StatusBadge` widget tự tạo)

- Bố cục: `Container` dạng pill (`AppRadius.brFull`), chiều cao 24px, `padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2)`.
- Bên trong: `Row(mainAxisSize: MainAxisSize.min)` gồm `Icon(size: 14)` + `SizedBox(width: 4)` + `Text(style: AppTextStyles.caption)`.
- Nền dùng màu Light (`successLight`, `warningLight`...), chữ và icon dùng màu đậm tương ứng.
- Phải dùng đúng bảng màu ở mục 2.5, không tự chế màu.

### 6.4 Bảng dữ liệu (`DataTable` / `PaginatedDataTable`)

- Header: `headingRowColor: WidgetStatePropertyAll(AppColors.neutral100)`, chữ `AppTextStyles.caption` w600.
- Chiều cao hàng: `dataRowMinHeight: 40`, `dataRowMaxHeight: 48`.
- Hover: `WidgetStateProperty.resolveWith` trả về `AppColors.neutral50` khi hovered.
- Căn lề: cột chữ `numeric: false` (căn trái), cột số/tiền `numeric: true` (căn phải); cột trạng thái bọc `StatusBadge`.
- Tải dữ liệu: hiển thị skeleton (dùng package `shimmer` hoặc container màu `neutral200` mờ); rỗng: hiển thị `EmptyStateWidget` với icon 24px + text phụ.

### 6.5 Card

- Dùng `Card` hoặc `Container` với `decoration`:
  - `color: AppColors.white`
  - `borderRadius: AppRadius.brLg`
  - `border: Border.all(color: AppColors.neutral200)`
  - `boxShadow: AppShadows.sm`
  - `padding: AppSpacing.p5` (24px)
- Card thống kê:
  - Bố cục: `Column` gồm số lớn (`AppTextStyles.display`) + nhãn (`AppTextStyles.caption`) + widget xu hướng.

### 6.6 Dialog / Modal

- Dùng `showDialog` với `Dialog`:
  - `maxWidth: 480` (xác nhận), `640` (form).
  - `barrierColor: AppColors.charcoal900.withValues(alpha: 0.5)`.
  - `shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg)`.
- Hàng nút hành động: `Row(mainAxisAlignment: MainAxisAlignment.end)`:
  - `OutlinedButton` (Hủy/Đóng) bên trái.
  - `ElevatedButton` (Xác nhận / Primary / Danger) bên phải.
- Hành động xóa/phá hủy: dialog xác nhận nền nút đỏ `AppColors.danger`, mô tả hậu quả rõ ràng.

### 6.7 Thông báo (Toast & Alert)

- **Toast / SnackBar**:
  - Dùng `ScaffoldMessenger.of(context).showSnackBar`.
  - `behavior: SnackBarBehavior.floating`, đặt góc trên hoặc dưới tuỳ bố cục desktop.
  - `duration: Duration(seconds: 4)` (lỗi: không tự ẩn hoặc tăng lên 8 giây).
  - Bo góc `AppRadius.brMd`.
- **Alert inline**:
  - `Container` có `decoration`: nền `semanticLight`, viền trái `Border(left: BorderSide(width: 4, color: semanticColor))`.
  - `padding: AppSpacing.p4`.
  - Bên trong: `Row` với icon ngữ nghĩa bên trái + nội dung ngắn gọn bên phải.

## 7. Màn hình đặc thù

### 7.1 Check-in / Check-out tại quầy

1. **Ô quét mã** (thẻ bạn đọc, mã sách): to (`height: 48`), nằm trên cùng, gán `FocusNode` tự động focus khi mở màn hình và re-focus sau mỗi lần hoàn thành.
2. **Hiển thị kết quả tức thì**: sau khi `onSubmitted` được gọi, render ngay thẻ thông tin bạn đọc/sách, trạng thái, hạn trả.
3. **Phản hồi**:
   - Thành công: `StatusBadge(Đã trả)` + floating `SnackBar` màu success.
   - Thất bại (quá hạn, sách đã đặt trước): `Alert inline` màu danger/warning nêu rõ lý do.
4. **Phím tắt**:
   - Dùng `Shortcuts` + `Actions` của Flutter:
     - `LogicalKeyboardKey.enter`: xác nhận thao tác.
     - `LogicalKeyboardKey.escape`: hủy / xóa trắng ô quét.
   - Nút Primary kích thước `lg` (48px).

### 7.2 Danh sách mượn / trả

- Bộ lọc trạng thái: dùng `FilterChip` / `ChoiceChip`, màu trùng bảng mục 2.5.
- Mặc định sort theo hạn trả gần nhất.
- Hàng quá hạn: highlight bằng viền trái 3px màu `AppColors.danger` trên ô đầu tiên hoặc toàn bộ hàng.

## 8. Icon

- Bộ icon: **Material Icons** tích hợp sẵn (`Icons.*`) hoặc **lucide_icons** (qua pub package `lucide_icons`). Chọn một bộ và dùng nhất quán toàn dự án.
- Kích thước chuẩn:
  - `16px`: trong text, inline badge.
  - `20px`: trong nút (`ElevatedButton.icon`), menu, navigation rail.
  - `24px`: tiêu đề section, icon trạng thái rỗng (`EmptyState`).
- Màu: mặc định kế thừa `IconTheme`, hoặc truyền đúng màu token (`AppColors.*`).
- Icon nút đứng riêng (không có text) bắt buộc bọc `IconButton` có `tooltip: 'Mô tả hành động'`.

## 9. Chuyển động (Animation)

- Hằng số thời lượng (`Duration`):
  - `AppDurations.fast = Duration(milliseconds: 150)` (hover, focus).
  - `AppDurations.normal = Duration(milliseconds: 200)` (mở/đóng dropdown, expand).
  - `AppDurations.slow = Duration(milliseconds: 300)` (dialog, drawer, page transition).
- Easing:
  - Xuất hiện: `Curves.easeOut`.
  - Biến mất: `Curves.easeIn`.
- Hỗ trợ `prefers-reduced-motion`: kiểm tra `MediaQuery.disableAnimationsOf(context)`, nếu `true` thì tắt `AnimationController` hoặc đặt thời lượng về `Duration.zero`.

## 10. Khả năng truy cập (Accessibility / A11y)

- Tương phản chữ tối thiểu 4.5:1, thành phần UI 3:1.
- Toàn bộ flow check-in/out thao tác được hoàn toàn bằng bàn phím qua `FocusTraversalGroup` và `FocusNode`.
- Target bấm tối thiểu `40×40` px trên desktop, `48×48` px trên mobile/tablet cảm ứng (`materialTapTargetSize: MaterialTapTargetSize.padded`).
- Ô nhập liệu luôn có `Semantics` hoặc `InputDecoration.labelText` rõ ràng.
- Đọc lỗi cho trình đọc màn hình bằng `Semantics(liveRegion: true)`.
- Không biểu đạt trạng thái chỉ bằng màu: luôn đi kèm icon + text.

## 11. Nội dung và ngôn ngữ

- Ngôn ngữ giao diện: tiếng Việt, xưng hô trung tính, ngắn gọn.
- Nút bấm dùng động từ hành động: "Check-in", "Check-out", "Lưu", "Hủy", "Xóa".
- Định dạng ngày giờ: dùng package `intl`:
  - Ngày: `DateFormat('dd/MM/yyyy').format(date)`
  - Giờ: `DateFormat('HH:mm').format(time)`
- Thông báo lỗi nói rõ nguyên nhân và hướng xử lý tiếp theo, không hiển thị exception kỹ thuật cho người dùng.

## 12. Quy ước đặt tên và cấu trúc file (Flutter)

- **Token màu/spacing**: đặt tên theo vai trò (`AppColors.danger`), không đặt theo mã màu (`AppColors.red`).
- **File**: snake_case theo chuẩn Dart:
  - `lib/core/theme/app_colors.dart`
  - `lib/core/theme/app_spacing.dart`
  - `lib/core/theme/app_text_styles.dart`
  - `lib/core/theme/app_theme.dart`
  - `lib/shared/widgets/status_badge.dart`
  - `lib/shared/widgets/scan_input.dart`
- **Widget / Class**: PascalCase (`StatusBadge`, `ScanInput`, `AppColors`).
- **Hằng số**: camelCase (`charcoal900`, `s4`, `brMd`).
- Mỗi custom widget phải hỗ trợ đủ trạng thái: default, hover (desktop), focus, disabled (`onPressed: null`), loading, error.
- Không hard-code `Color(0x...)`, `EdgeInsets.all(...)` với số lẻ ngoài token; cần thêm giá trị mới phải cập nhật file này trước.

## 13. Checklist trước khi merge PR UI (Flutter)

- [ ] Chỉ dùng `AppColors`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppTextStyles` đã định nghĩa
- [ ] Trạng thái nghiệp vụ dùng đúng `StatusBadge` theo bảng mục 2.5
- [ ] Mọi nút và input có đủ trạng thái hover/focus/disabled/loading/error
- [ ] Ô quét mã tự động focus và xử lý được phím Enter/Esc
- [ ] Layout co giãn tốt ở độ phân giải 1024px và 1280px (Desktop / Tablet ngang)
- [ ] Có `EmptyStateWidget` khi danh sách rỗng và skeleton/shimmer khi đang tải
- [ ] Định dạng ngày tháng dùng `intl` đúng mẫu `dd/MM/yyyy`, giờ `HH:mm`
- [ ] Chạy `flutter analyze` không có warning/error, tuân thủ `flutter_lints`

---

*Phiên bản 1.1 (Flutter Edition). Cập nhật chuyển đổi toàn bộ token CSS sang Dart, hỗ trợ Material 3, Keyboard Shortcuts và cấu trúc dự án Flutter.*

### Lịch sử thay đổi

| Phiên bản | Nội dung |
|---|---|
| 1.0 | Khởi tạo bộ quy chuẩn web (CSS tokens, HTML/React specs) |
| 1.1 | Chuyển đổi sang Flutter/Dart: AppColors, AppSpacing, ThemeData Material 3, TextStyle, Shortcuts/FocusNode cho máy quét, quy ước đặt tên file Dart |
