# Agent Guidelines: Working with `docs/screen.mmd`

Tài liệu quy định nguyên tắc và quy trình bắt buộc cho mọi Agent khi làm việc với `docs/screen.mmd`.

---

## 1. Nguyên tắc cốt lõi (Core Principles)

1. **Single Source of Truth**:
   - `docs/screen.mmd` là chuẩn duy nhất định nghĩa cấu trúc màn hình và luồng điều hướng (navigation flow) của ứng dụng Flutter (`fe/`).
   - Mọi thay đổi về màn hình hoặc luồng chuyển trang trong code phải phản ánh chính xác trong file này.

2. **Spec-first (Luôn cập nhật trước khi code)**:
   - Trước khi triển khai màn hình Flutter mới: Phải cập nhật `docs/screen.mmd` trước.
   - Không code UI khi màn hình chưa có trong `docs/screen.mmd`.

3. **Ngôn ngữ (Language)**:
   - 100% tiếng Anh cho tất cả: tên node, ID node, nhãn điều hướng (edge labels), ghi chú luồng (flow comments).

4. **Tối giản nội dung (Minimalist Content)**:
   - Node chỉ chứa tên màn hình/thành phần UI: `[Name Screen]`, `[Name Modal]`, `[Name Dialog]`.
   - **Tuyệt đối không** đưa chi tiết triển khai vào node: không liệt kê field form, không bullet points, không ghi rule nghiệp vụ.
   - Logic, phân quyền, điều kiện chỉ thể hiện trên nhãn cạnh nối: `-->|Role / Action / Condition|`.

---

## 2. Quy chuẩn cú pháp Mermaid (Syntax Rules)

- **Diagram Type**: `flowchart TD`
- **Node ID**: `PascalCase` rõ nghĩa (ví dụ: `ReaderHome`, `StaffList`, `CreateStaffModal`).
- **Hình dạng Node**:
  - Điểm khởi đầu / Portal chính: `([Name Screen])`
  - Màn hình thông thường: `[Name Screen]`
  - Modal / Sheet: `[Name Modal]`
  - Dialog / Pop-up: `[Name Dialog]`
- **Cạnh nối (Edges)**:
  - Điều hướng xuôi: `A -->|Action / Trigger| B`
  - Chuyển đổi qua lại (toggle/switch): `A <-->|Label| B`
  - Hành động theo quyền/điều kiện đặc biệt: `A -.->|Admin: Action| B`
  - Tự cập nhật/refresh tại chỗ: `A -->|Save success| A`

---

## 3. Quy trình làm việc bắt buộc cho Agent (Agent Workflow)

1. **Đọc và đối chiếu**:
   - Đọc `docs/screen.mmd` để hiểu rõ ngữ cảnh luồng hiện tại trước khi đề xuất thay đổi.
2. **Cập nhật sơ đồ**:
   - Thêm/sửa node và cạnh nối theo đúng quy chuẩn Mục 1 & 2.
3. **Validate cú pháp**:
   - Chạy công cụ kiểm tra cú pháp Mermaid (`mermaid-diagram-validator`) để đảm bảo không lỗi cú pháp.
4. **Preview sơ đồ**:
   - Mở xem trước (`mermaid-diagram-preview`) để kiểm tra tính trực quan và liên kết.
5. **Triển khai code Frontend**:
   - Tạo route (`routes/`) và view/page (`features/`) bám sát tên và luồng trong `docs/screen.mmd`.
