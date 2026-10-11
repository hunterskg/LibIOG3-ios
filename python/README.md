# Python Face Recognition & Liveness Service (gRPC)

Service xử lý pipeline sinh trắc học khuôn mặt bằng AI/ML phục vụ backend NestJS qua giao thức gRPC.

---

## 1. Tổng quan & Vai trò

Hệ thống hoạt động theo mô hình client-backend:
```text
Client (Web / Mobile)
   ↓ HTTP / WebSocket
NestJS Backend (Business logic, Auth, PostgreSQL + pgvector)
   ↓ gRPC (Internal Network)
Python Face Service (AI Inference)
   ├── 1. Face Detection
   ├── 2. Face Quality Check
   ├── 3. Liveness Detection (Anti-Spoofing)
   └── 4. Face Embedding Extraction
```

### Nguyên tắc cốt lõi:
- **Python Service KHÔNG kết nối database**: Chỉ nhận ảnh dạng bytes từ NestJS, chạy model AI và trả metadata/vector embedding.
- **NestJS quản lý lưu trữ & tìm kiếm**: Lưu vector vào PostgreSQL (pgvector), query Top-K similarity.
- **Pipeline bảo mật nghiêm ngặt**:
  $$\text{Face Detection} \rightarrow \text{Quality Check} \rightarrow \text{Liveness Check} \rightarrow \text{Embedding Extraction}$$
  *Không bao giờ bỏ qua bước Liveness trước khi trích xuất vector.*

---

## 2. Kiến trúc Clean Architecture

Dự án tuân thủ Clean Architecture (Hexagonal Architecture) để tách biệt domain logic và thư viện AI bên ngoài (InsightFace, ONNX, OpenCV):

```text
python/
├── proto/                          # Contract định nghĩa giao tiếp gRPC
│   └── face/v1/face.proto
│
├── app/
│   ├── domain/                     # Core nghiệp vụ, độc lập hoàn toàn với framework/AI
│   │   ├── entities/               # Thực thể (Face, LivenessResult)
│   │   ├── value_objects/          # BoundingBox, Landmark, Embedding
│   │   ├── exceptions/             # Domain exceptions
│   │   └── services/               # Logic tính toán thuần túy (Cosine Similarity)
│   │
│   ├── application/                # Điều phối quy trình nghiệp vụ (Use Cases)
│   │   ├── ports/                  # Protocol/Interface (FaceDetector, FaceEmbedder, LivenessDetector)
│   │   └── use_cases/              # Luồng thực thi (DetectFace, ExtractEmbedding, VerifyFace, CheckLiveness)
│   │
│   ├── infrastructure/             # Triển khai chi tiết kỹ thuật & adapter
│   │   ├── adapters/               # Hiện thực hóa các Port (InsightFace, ONNX, OpenCV, Stubs)
│   │   └── config/                 # Pydantic Settings đọc biến môi trường
│   │
│   └── interfaces/                 # Giao diện đầu vào hệ thống
│       └── grpc/                   # Server, Servicer, Interceptors (Logging, Error handling)
│
├── bootstrap.py                    # Wire Dependency Injection (DI Container)
├── main.py                         # Entrypoint khởi động gRPC server
└── tests/                          # Unit test & Integration test
```

---

## 3. Bản đồ luồng dữ liệu (Data Flow)

Khi một request gRPC đến:

```text
1. NestJS gọi gRPC RPC (vd: VerifyFace)
         ↓
2. GrpcInterceptor: Bắt đầu log request, kiểm tra deadline, đo thời gian xử lý
         ↓
3. FaceServiceServicer: Parse dữ liệu từ Protobuf Request sang Domain Types
         ↓
4. VerifyFaceUseCase (Application Layer):
     ├── Gọi FaceDetector (Port)  → Trả về DetectedFace
     ├── Gọi LivenessDetector (Port) → Trả về LivenessResult
     └── Gọi FaceEmbedder (Port)    → Trả về Embedding
     └── Gọi similarity_service     → Tính Cosine Similarity với vector gốc
         ↓
5. FaceServiceServicer: Đóng gói kết quả thành Protobuf Response trả về cho NestJS
```

---

## 4. Bắt đầu nhanh cho thành viên mới

### Yêu cầu môi trường
- Python `>= 3.11`
- Package manager: [`uv`](https://docs.astral.sh/uv/) (bắt buộc, không dùng `pip` hay `poetry`)

### Cài đặt môi trường
Tại thư mục `python/`:

```bash
# Cài đặt uv nếu máy chưa có
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

# Đồng bộ dependencies vào môi trường ảo (.venv)
uv sync --extra dev
```

### Thiết lập biến môi trường
Tạo file `.env` từ file mẫu:
```bash
cp .env.example .env
```

Các biến môi trường quan trọng:
| Biến | Ý nghĩa | Mặc định |
| :--- | :--- | :--- |
| `APP_ENV` | Môi trường (`development` / `production`) | `development` |
| `GRPC_HOST` | Host lắng nghe gRPC | `0.0.0.0` |
| `GRPC_PORT` | Port gRPC service | `50051` |
| `LIVENESS_MODEL_PATH` | Đường dẫn file model ONNX anti-spoofing | `/models/liveness/model.onnx` |
| `FACE_MIN_DETECTION_SCORE` | Ngưỡng tin cậy tối thiểu khi detect mặt | `0.6` |
| `FACE_MATCH_THRESHOLD` | Ngưỡng cosine similarity để tính là match | `0.6` |

---

## 5. Các lệnh phát triển (Developer CLI)

Mọi thao tác phát triển đều chạy qua `uv`:

### Khởi chạy Service (Run Server)
```bash
# Chạy trực tiếp qua uv
uv run python main.py

# Hoặc kích hoạt venv rồi chạy python trực tiếp
# Windows (PowerShell): .\.venv\Scripts\Activate.ps1
# Linux/macOS: source .venv/bin/activate
python main.py

# Hoặc chạy bằng Docker Compose
docker compose up --build
```

### Chạy kiểm thử (Testing)
```bash
uv run --extra dev pytest
```

### Kiểm tra cú pháp & Format (Linter)
```bash
# Kiểm tra lỗi lint
uv run ruff check .

# Tự động sửa lỗi lint có thể
uv run ruff check --fix .

# Định dạng code
uv run ruff format .
```

### Kiểm tra kiểu tĩnh (Type Checking)
```bash
uv run mypy .
```

### Sinh mã từ Protobuf (`.proto`)
Khi thay đổi `proto/face/v1/face.proto`:
```bash
uv run python -m grpc_tools.protoc \
    -I. \
    --python_out=. \
    --grpc_python_out=. \
    proto/face/v1/face.proto
```

---

## 6. Lộ trình thực hiện khi chuyển từ Khung (Stubs) sang Production Code

Dự án hiện đang ở trạng thái **Khung (Skeleton/Stubs)**: Tất cả methods khai báo `raise NotImplementedError`.

Thứ tự các bước triển khai logic thực tế:

1. **Domain Layer (`app/domain/`)**:
   - Hoàn thiện hàm tính toán vector tại `app/domain/services/similarity.py` (công thức Cosine Similarity trên NumPy).
   - Bổ sung quy tắc kiểm tra chất lượng ảnh (độ mờ, góc xoay pitch/yaw) tại entity `Face`.

2. **Infrastructure Adapters (`app/infrastructure/adapters/`)**:
   - `InsightFaceDetector`: Tải model detector (`buffalo_l` hoặc `scrfd`), tiền xử lý ảnh OpenCV, map kết quả sang `DetectedFace`.
   - `InsightFaceEmbedder`: Trích xuất vector 512 chiều từ khuôn mặt đã cắt/căn chỉnh (aligned face), chuẩn hóa $L_2$.
   - `OnnxLivenessDetector`: Nạp ONNX Runtime session, suy luận liveness từ frame ảnh/video.

3. **Application Use Cases (`app/application/use_cases/`)**:
   - Xâu chuỗi các Ports theo đúng pipeline: `Detector` $\rightarrow$ `Liveness` $\rightarrow$ `Embedder`.

4. **gRPC Interface (`app/interfaces/grpc/`)**:
   - Hoàn thiện mapping từ protobuf message sang domain entities và ngược lại.
   - Xử lý gRPC Error Status Code tương ứng với Domain Exceptions.

5. **Bootstrap (`bootstrap.py`) & Entrypoint (`main.py`)**:
   - Khởi tạo model một lần duy nhất lúc startup (warm-up model).
   - Đăng ký servicer vào gRPC server và kích hoạt graceful shutdown.
