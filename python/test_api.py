"""Lightweight HTTP API Server để upload và so sánh 2 ảnh nhận diện khuôn mặt."""

import argparse
import base64
import email
import email.policy
import io
import json
import logging
import math
import sys
import time
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any, Protocol

import cv2
import grpc
import numpy as np
from PIL import Image, ImageOps

from app.infrastructure.adapters.insightface_detector import InsightFaceDetector
from app.infrastructure.adapters.insightface_embedder import (
    ARCFACE_DST_112,
    InsightFaceEmbedder,
)
from app.infrastructure.adapters.numpy_similarity_calculator import NumpySimilarityCalculator
from app.infrastructure.config.settings import AppSettings
from proto.face.v1 import face_pb2, face_pb2_grpc

logger = logging.getLogger("face_test_api")

DEFAULT_GRPC_ADDRESS = "localhost:50051"
DEFAULT_MATCH_THRESHOLD = 0.68


def normalize_image_bytes(image_bytes: bytes) -> bytes:
    """Xoay ảnh theo chuẩn EXIF orientation (tránh ảnh chụp điện thoại bị xoay ngang/ngược)."""
    try:
        pil_img = Image.open(io.BytesIO(image_bytes))
        transposed = ImageOps.exif_transpose(pil_img)
        if transposed is not pil_img or pil_img.format != "JPEG" or pil_img.mode != "RGB":
            bio = io.BytesIO()
            if transposed.mode != "RGB":
                transposed = transposed.convert("RGB")
            transposed.save(bio, format="JPEG", quality=95)
            return bio.getvalue()
    except (OSError, ValueError) as exc:
        logger.debug("Bỏ qua lỗi xử lý EXIF: %s", exc)
    return image_bytes


def align_face_112(image_bytes: bytes, landmarks: Any) -> np.ndarray | None:
    """Căn chỉnh khuôn mặt về chuẩn ArcFace 112x112 qua cv2.estimateAffinePartial2D."""
    try:
        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if img is None:
            return None
        if landmarks is not None and hasattr(landmarks, "points") and len(landmarks.points) >= 5:
            kps = np.array([[pt.x, pt.y] for pt in landmarks.points[:5]], dtype=np.float32)
            affine_matrix, _ = cv2.estimateAffinePartial2D(kps, ARCFACE_DST_112)
            if affine_matrix is not None:
                return cv2.warpAffine(img, affine_matrix, (112, 112), borderValue=0.0)
    except (ValueError, cv2.error) as exc:
        logger.debug("Bỏ qua lỗi căn chỉnh khuôn mặt: %s", exc)
    return None


def get_aligned_crop_b64(image_bytes: bytes, landmarks: Any) -> str | None:
    """Tạo thumbnail base64 của khuôn mặt đã căn chỉnh 112x112 để trực quan hóa."""
    face_img = align_face_112(image_bytes, landmarks)
    if face_img is None:
        return None
    try:
        _, buf = cv2.imencode(".jpg", face_img)
        return base64.b64encode(buf.tobytes()).decode("ascii")
    except cv2.error as exc:
        logger.debug("Bỏ qua lỗi tạo thumbnail crop: %s", exc)
        return None


def compute_match_confidence(similarity: float) -> float:
    """Quy đổi cosine similarity sang thang đo độ tin cậy nhận diện (%) chuẩn eKYC sinh trắc học."""
    if similarity <= 0.20:
        return max(0.0, round((similarity / 0.20) * 20.0, 1))
    if similarity < 0.45:
        return round(20.0 + ((similarity - 0.20) / 0.25) * 50.0, 1)
    if similarity < 0.65:
        return round(70.0 + ((similarity - 0.45) / 0.20) * 25.0, 1)
    return round(95.0 + min(4.9, ((similarity - 0.65) / 0.20) * 4.9), 1)


HTML_PAGE = """<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Face Comparison Test</title>
  <style>
    :root { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0f172a; color: #f8fafc; }
    body { max-width: 900px; margin: 30px auto; padding: 0 20px; }
    h1 { font-size: 24px; font-weight: 700; margin-bottom: 6px; }
    p.sub { color: #94a3b8; font-size: 14px; margin-top: 0; margin-bottom: 24px; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
    .card { background: #1e293b; border: 1px solid #334155; border-radius: 12px; padding: 18px; }
    .card h3 { margin: 0 0 12px 0; font-size: 16px; color: #e2e8f0; }
    .dropzone { border: 2px dashed #475569; border-radius: 8px; padding: 20px; text-align: center; cursor: pointer; background: #0f172a80; }
    .dropzone:hover { border-color: #38bdf8; }
    input[type="file"] { display: none; }
    img.preview { max-width: 100%; max-height: 220px; object-fit: contain; margin-top: 10px; border-radius: 6px; display: none; }
    .controls { margin-top: 20px; display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
    label { font-size: 14px; color: #cbd5e1; }
    input[type="number"] { background: #1e293b; border: 1px solid #475569; color: #f8fafc; padding: 8px 12px; border-radius: 6px; width: 75px; }
    .preset-btn { background: #334155; color: #cbd5e1; border: 1px solid #475569; padding: 6px 12px; font-size: 12px; border-radius: 6px; cursor: pointer; }
    .preset-btn:hover { background: #475569; }
    button.submit-btn { background: #0284c7; color: white; border: none; padding: 10px 24px; font-size: 15px; font-weight: 600; border-radius: 8px; cursor: pointer; transition: 0.2s; margin-left: auto; }
    button.submit-btn:hover { background: #0369a1; }
    button:disabled { opacity: 0.5; cursor: not-allowed; }
    .result { margin-top: 24px; padding: 20px; border-radius: 10px; display: none; }
    .result.matched { background: #064e3b; border: 1px solid #059669; }
    .result.unmatched { background: #7f1d1d; border: 1px solid #dc2626; }
    .result.error { background: #78350f; border: 1px solid #d97706; }
    .score { font-size: 26px; font-weight: 800; margin: 4px 0; }
    .crops-container { display: flex; gap: 20px; margin: 15px 0; align-items: center; background: #0f172a60; padding: 12px; border-radius: 8px; }
    .crop-item { text-align: center; }
    .crop-item img { width: 112px; height: 112px; border-radius: 8px; border: 2px solid #38bdf8; object-fit: cover; }
    .crop-item span { display: block; font-size: 12px; color: #94a3b8; margin-top: 4px; }
    .expl-box { margin-top: 10px; font-size: 13px; color: #cbd5e1; background: #1e293b; padding: 10px; border-radius: 6px; border-left: 4px solid #38bdf8; }
    pre { background: #0b1120; padding: 12px; border-radius: 6px; overflow-x: auto; font-size: 12px; }
  </style>
</head>
<body>
  <h1>Kiểm tra nhận diện 2 khuôn mặt</h1>
  <p class="sub">Tự động căn chỉnh góc xoay EXIF, chuẩn hóa 5 điểm mốc ArcFace và đối sánh đặc trưng sinh trắc học.</p>

  <form id="compareForm">
    <div class="grid">
      <div class="card">
        <h3>Ảnh 1 (Reference)</h3>
        <div class="dropzone" onclick="document.getElementById('img1').click()">
          <span id="label1">Chọn hoặc kéo thả ảnh 1</span>
          <input type="file" id="img1" name="image1" accept="image/*" required>
          <img id="prev1" class="preview" alt="Preview 1">
        </div>
      </div>
      <div class="card">
        <h3>Ảnh 2 (Candidate)</h3>
        <div class="dropzone" onclick="document.getElementById('img2').click()">
          <span id="label2">Chọn hoặc kéo thả ảnh 2</span>
          <input type="file" id="img2" name="image2" accept="image/*" required>
          <img id="prev2" class="preview" alt="Preview 2">
        </div>
      </div>
    </div>

    <div class="controls">
      <label>Ngưỡng Cosine (Threshold):</label>
      <input type="number" id="threshold" name="threshold" value="0.45" step="0.05" min="0" max="1">
      <button type="button" class="preset-btn" onclick="setThresh(0.40)">0.40 (Nới lỏng - Ảnh đời thường)</button>
      <button type="button" class="preset-btn" onclick="setThresh(0.45)">0.45 (Chuẩn ArcFace FAR 10⁻⁴)</button>
      <button type="button" class="preset-btn" onclick="setThresh(0.55)">0.55 (Bảo mật cao - Ảnh thẻ)</button>
      <button type="submit" id="btnSubmit" class="submit-btn">So sánh 2 ảnh</button>
    </div>
  </form>

  <div id="resultBox" class="result">
    <div id="resultStatus" class="score"></div>
    <div id="resultDesc"></div>
    
    <div id="cropsBox" class="crops-container" style="display:none;">
      <div class="crop-item">
        <img id="cropImg1" alt="Face 1">
        <span id="cropLabel1">Face 1 (Aligned 112x112)</span>
      </div>
      <div style="font-size: 20px; font-weight: bold; color: #94a3b8;">VS</div>
      <div class="crop-item">
        <img id="cropImg2" alt="Face 2">
        <span id="cropLabel2">Face 2 (Aligned 112x112)</span>
      </div>
    </div>

    <div class="expl-box">
      <strong>Lưu ý về thang đo:</strong> Trong không gian ArcFace 512 chiều, 2 người khác nhau có Cosine Similarity chỉ từ 0.00 đến 0.20. Hai ảnh cùng người khác góc/thời điểm thường đạt 0.45 - 0.65 (tương đương độ tin cậy > 75%).
    </div>

    <pre id="resultJson"></pre>
  </div>

  <script>
    function setThresh(v) {
      document.getElementById('threshold').value = v.toFixed(2);
    }

    function bindPreview(inputId, prevId, labelId) {
      document.getElementById(inputId).addEventListener('change', e => {
        const file = e.target.files[0];
        if (file) {
          const reader = new FileReader();
          reader.onload = ev => {
            const p = document.getElementById(prevId);
            p.src = ev.target.result;
            p.style.display = 'block';
            document.getElementById(labelId).innerText = file.name;
          };
          reader.readAsDataURL(file);
        }
      });
    }
    bindPreview('img1', 'prev1', 'label1');
    bindPreview('img2', 'prev2', 'label2');

    document.getElementById('compareForm').addEventListener('submit', async e => {
      e.preventDefault();
      const btn = document.getElementById('btnSubmit');
      const box = document.getElementById('resultBox');
      const statusEl = document.getElementById('resultStatus');
      const descEl = document.getElementById('resultDesc');
      const jsonEl = document.getElementById('resultJson');
      const cropsBox = document.getElementById('cropsBox');
      const cropImg1 = document.getElementById('cropImg1');
      const cropImg2 = document.getElementById('cropImg2');

      btn.disabled = true;
      btn.innerText = 'Đang nhận diện...';
      box.style.display = 'none';
      cropsBox.style.display = 'none';

      const formData = new FormData();
      formData.append('image1', document.getElementById('img1').files[0]);
      formData.append('image2', document.getElementById('img2').files[0]);
      formData.append('threshold', document.getElementById('threshold').value);

      try {
        const res = await fetch('/compare', { method: 'POST', body: formData });
        const data = await res.json();
        box.style.display = 'block';
        jsonEl.innerText = JSON.stringify(data, null, 2);

        if (data.crops && data.crops.face1 && data.crops.face2) {
          cropImg1.src = 'data:image/jpeg;base64,' + data.crops.face1;
          cropImg2.src = 'data:image/jpeg;base64,' + data.crops.face2;
          cropsBox.style.display = 'flex';
        }

        if (data.error) {
          box.className = 'result error';
          statusEl.innerText = 'LỖI: ' + data.error;
          descEl.innerText = '';
        } else if (data.matched) {
          box.className = 'result matched';
          statusEl.innerText = `CÙNG MỘT NGƯỜI (Độ tin cậy: ${data.match_confidence}%)`;
          descEl.innerText = `Cosine Similarity: ${data.similarity} | Khoảng cách Euclidean: ${data.euclidean_distance} (Ngưỡng: ${data.threshold}) | Đánh giá: ${data.security_level}`;
        } else {
          box.className = 'result unmatched';
          statusEl.innerText = `KHÁC NGƯỜI (Độ tin cậy: ${data.match_confidence}%)`;
          descEl.innerText = `Cosine Similarity: ${data.similarity} | Khoảng cách Euclidean: ${data.euclidean_distance} (Ngưỡng: ${data.threshold}) | Đánh giá: ${data.security_level}`;
        }
      } catch (err) {
        box.style.display = 'block';
        box.className = 'result error';
        statusEl.innerText = 'Lỗi kết nối';
        descEl.innerText = err.message;
      } finally {
        btn.disabled = false;
        btn.innerText = 'So sánh 2 ảnh';
      }
    });
  </script>
</body>
</html>
"""


class FaceComparatorService:
    """Service xử lý so sánh nhận diện khuôn mặt giữa 2 ảnh."""

    def __init__(self, settings: AppSettings | None = None) -> None:
        cfg = settings or AppSettings()
        self.settings = cfg
        self.detector = InsightFaceDetector(
            model_name=cfg.insightface_model_name,
            model_root=cfg.model_root_dir,
        )
        self.embedder = InsightFaceEmbedder(
            model_path=cfg.embedder_model_path,
            model_name=cfg.insightface_model_name,
            model_root=cfg.model_root_dir,
        )
        self.similarity_calculator = NumpySimilarityCalculator()

    def compare(
        self,
        image1_bytes: bytes,
        image2_bytes: bytes,
        threshold: float | None = None,
    ) -> dict[str, Any]:
        """So khớp 2 ảnh và tính độ tương đồng khuôn mặt."""
        start_time = time.perf_counter()
        thresh = threshold if threshold is not None else self.settings.face_match_threshold

        if not image1_bytes:
            return {"error": "Ảnh 1 không được để trống", "matched": False}
        if not image2_bytes:
            return {"error": "Ảnh 2 không được để trống", "matched": False}

        # Tự động chuẩn hóa góc quay EXIF cho ảnh chụp từ điện thoại
        img1_norm = normalize_image_bytes(image1_bytes)
        img2_norm = normalize_image_bytes(image2_bytes)

        faces1 = self.detector.detect(img1_norm)
        if not faces1:
            return {"error": "Không tìm thấy khuôn mặt trong ảnh 1", "matched": False}

        faces2 = self.detector.detect(img2_norm)
        if not faces2:
            return {"error": "Không tìm thấy khuôn mặt trong ảnh 2", "matched": False}

        # Ưu tiên khuôn mặt có diện tích lớn nhất kết hợp độ tự tin cao
        target_face1 = max(faces1, key=lambda f: (f.bbox.width * f.bbox.height) * (f.confidence**2))
        target_face2 = max(faces2, key=lambda f: (f.bbox.width * f.bbox.height) * (f.confidence**2))

        emb1 = self.embedder.extract_embedding(
            img1_norm, bbox=target_face1.bbox, landmarks=target_face1.landmarks
        )
        emb2 = self.embedder.extract_embedding(
            img2_norm, bbox=target_face2.bbox, landmarks=target_face2.landmarks
        )

        similarity = float(self.similarity_calculator.compute_cosine_similarity(emb1, emb2))
        matched = similarity >= thresh
        euclidean_dist = round(math.sqrt(max(0.0, 2.0 * (1.0 - similarity))), 4)
        match_confidence = compute_match_confidence(similarity)

        if similarity >= 0.55:
            security_level = "Trùng khớp cực cao (FAR < 0.001%)"
        elif similarity >= 0.45:
            security_level = "Trùng khớp độ tin cậy cao (FAR < 0.01%)"
        elif similarity >= 0.38:
            security_level = "Trùng khớp mức chấp nhận được (FAR ~ 0.1%)"
        else:
            security_level = "Không trùng khớp (Negative)"

        elapsed_ms = (time.perf_counter() - start_time) * 1000.0

        crop1_b64 = get_aligned_crop_b64(img1_norm, target_face1.landmarks)
        crop2_b64 = get_aligned_crop_b64(img2_norm, target_face2.landmarks)

        return {
            "matched": matched,
            "similarity": round(similarity, 4),
            "match_confidence": match_confidence,
            "security_level": security_level,
            "euclidean_distance": euclidean_dist,
            "threshold": thresh,
            "crops": {
                "face1": crop1_b64,
                "face2": crop2_b64,
            },
            "faces_found": {
                "image1": len(faces1),
                "image2": len(faces2),
            },
            "elapsed_ms": round(elapsed_ms, 1),
        }


def create_handler(comparator: FaceComparatorService) -> type[BaseHTTPRequestHandler]:
    class FaceHttpHandler(BaseHTTPRequestHandler):
        def _send_json(self, status: int, data: dict[str, Any]) -> None:
            body = json.dumps(data, ensure_ascii=False).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(body)

        def do_OPTIONS(self) -> None:
            self.send_response(HTTPStatus.NO_CONTENT)
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
            self.send_header("Access-Control-Allow-Headers", "Content-Type")
            self.end_headers()

        def do_GET(self) -> None:
            if self.path in ("/", "/index.html"):
                body = HTML_PAGE.encode("utf-8")
                self.send_response(HTTPStatus.OK)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
            elif self.path == "/health":
                self._send_json(HTTPStatus.OK, {"status": "ok"})
            else:
                self._send_json(HTTPStatus.NOT_FOUND, {"error": "Not Found"})

        def do_POST(self) -> None:
            if self.path not in ("/compare", "/api/compare", "/verify"):
                self._send_json(HTTPStatus.NOT_FOUND, {"error": "Not Found"})
                return

            content_type = self.headers.get("Content-Type", "")
            content_length = int(self.headers.get("Content-Length", "0"))
            raw_body = self.rfile.read(content_length)

            img1_bytes: bytes | None = None
            img2_bytes: bytes | None = None
            threshold: float | None = None

            try:
                if "multipart/form-data" in content_type:
                    msg = email.message_from_bytes(
                        f"Content-Type: {content_type}\r\n\r\n".encode() + raw_body,
                        policy=email.policy.default,
                    )
                    for part in msg.iter_parts():
                        name = part.get_param("name", header="content-disposition")
                        payload = part.get_payload(decode=True)
                        if isinstance(payload, bytes):
                            if name == "image1":
                                img1_bytes = payload
                            elif name == "image2":
                                img2_bytes = payload
                            elif name == "threshold":
                                try:
                                    threshold = float(payload.decode("utf-8").strip())
                                except ValueError:
                                    pass
                elif "application/json" in content_type:
                    payload = json.loads(raw_body.decode("utf-8"))
                    raw1 = payload.get("image1", "")
                    raw2 = payload.get("image2", "")
                    img1_bytes = base64.b64decode(raw1.split(",")[-1]) if raw1 else None
                    img2_bytes = base64.b64decode(raw2.split(",")[-1]) if raw2 else None
                    if "threshold" in payload:
                        threshold = float(payload["threshold"])
                else:
                    self._send_json(
                        HTTPStatus.BAD_REQUEST,
                        {
                            "error": "Unsupported Content-Type. Dùng multipart/form-data hoặc application/json"
                        },
                    )
                    return

                if not img1_bytes or not img2_bytes:
                    self._send_json(
                        HTTPStatus.BAD_REQUEST,
                        {"error": "Thiếu image1 hoặc image2", "matched": False},
                    )
                    return

                result = comparator.compare(
                    image1_bytes=img1_bytes,
                    image2_bytes=img2_bytes,
                    threshold=threshold,
                )
                status_code = HTTPStatus.BAD_REQUEST if "error" in result else HTTPStatus.OK
                self._send_json(status_code, result)

            except Exception as exc:
                logger.exception("Error handling compare request")
                self._send_json(
                    HTTPStatus.INTERNAL_SERVER_ERROR,
                    {"error": str(exc), "matched": False},
                )

        def log_message(self, format: str, *args: Any) -> None:
            logger.info(
                "%s - - [%s] %s", self.client_address[0], self.log_date_time_string(), format % args
            )

    return FaceHttpHandler


def run_http_server(host: str = "0.0.0.0", port: int = 8000) -> None:
    """Khởi chạy HTTP server test nhận diện khuôn mặt."""
    logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
    comparator = FaceComparatorService()
    handler_class = create_handler(comparator)
    server = ThreadingHTTPServer((host, port), handler_class)
    logger.info("Face Comparison Test API running on http://%s:%d", host, port)
    logger.info("Mở trình duyệt: http://localhost:%d hoặc gọi POST /compare", port)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("Server shutting down...")
        server.server_close()


class FaceServiceClientProtocol(Protocol):
    """Protocol tương tác với Face Service (hỗ trợ Mock trong unit tests)."""

    def extract_embedding(self, image_bytes: bytes) -> list[float]: ...

    def verify_face(
        self,
        image_bytes: bytes,
        reference_embedding: list[float],
        threshold: float = DEFAULT_MATCH_THRESHOLD,
    ) -> tuple[bool, float]: ...


class FaceGrpcClient:
    """gRPC Client kết nối FaceService."""

    def __init__(
        self,
        target: str = DEFAULT_GRPC_ADDRESS,
        channel: grpc.Channel | None = None,
        stub: Any = None,
    ) -> None:
        self._target = target
        self._channel = channel
        self._stub = stub
        if self._stub is None:
            if self._channel is None:
                self._channel = grpc.insecure_channel(self._target)
            self._stub = face_pb2_grpc.FaceServiceStub(self._channel)  # type: ignore[no-untyped-call]

    def extract_embedding(self, image_bytes: bytes) -> list[float]:
        """Gọi RPC ExtractEmbedding."""
        request = face_pb2.ExtractEmbeddingRequest(image_bytes=image_bytes)
        response: face_pb2.ExtractEmbeddingResponse = self._stub.ExtractEmbedding(request)
        if not response.success:
            raise RuntimeError(f"ExtractEmbedding failed: {response.error}")
        return list(response.embedding.values)

    def verify_face(
        self,
        image_bytes: bytes,
        reference_embedding: list[float],
        threshold: float = DEFAULT_MATCH_THRESHOLD,
    ) -> tuple[bool, float]:
        """Gọi RPC VerifyFace."""
        proto_emb = face_pb2.FaceEmbedding(
            values=reference_embedding,
            dimension=len(reference_embedding),
        )
        request = face_pb2.VerifyFaceRequest(
            image_bytes=image_bytes,
            reference_embedding=proto_emb,
            threshold=threshold,
        )
        response: face_pb2.VerifyFaceResponse = self._stub.VerifyFace(request)
        if not response.success:
            raise RuntimeError(f"VerifyFace failed: {response.error}")
        return response.matched, float(response.similarity)

    def detect_faces(self, image_bytes: bytes, max_faces: int = 1) -> list[Any]:
        """Gọi RPC DetectFaces."""
        request = face_pb2.DetectFacesRequest(
            image_bytes=image_bytes,
            max_faces=max_faces,
        )
        response: face_pb2.DetectFacesResponse = self._stub.DetectFaces(request)
        if not response.success:
            raise RuntimeError(f"DetectFaces failed: {response.error}")
        return list(response.detections)

    def check_liveness(self, image_bytes: bytes) -> tuple[bool, float]:
        """Gọi RPC CheckLiveness."""
        request = face_pb2.CheckLivenessRequest(image_bytes=image_bytes)
        response: face_pb2.CheckLivenessResponse = self._stub.CheckLiveness(request)
        if not response.success:
            raise RuntimeError(f"CheckLiveness failed: {response.error}")
        is_real = response.status == face_pb2.LivenessStatus.LIVENESS_REAL
        return is_real, float(response.confidence)

    def close(self) -> None:
        """Đóng gRPC channel."""
        if self._channel is not None and hasattr(self._channel, "close"):
            self._channel.close()


class MultiSampleEnrollmentService:
    """Service đăng ký khuôn mặt đa mẫu (Multi-Sample Enrollment) và nhận diện."""

    def __init__(self, client: FaceServiceClientProtocol) -> None:
        self.client = client

    def enroll(self, image_bytes_list: list[bytes]) -> dict[str, Any]:
        """Đăng ký từ danh sách 3-5 ảnh mẫu, tính vector đại diện hợp nhất (average + L2 normalized)."""
        if not image_bytes_list:
            raise ValueError("image_bytes_list cannot be empty")
        if len(image_bytes_list) < 1:
            raise ValueError("Cần ít nhất 1 ảnh mẫu để đăng ký")

        sample_embeddings: list[list[float]] = []
        for idx, img_bytes in enumerate(image_bytes_list):
            emb = self.client.extract_embedding(img_bytes)
            # Kiểm tra và chuẩn hóa L2 cho từng mẫu
            arr = np.asarray(emb, dtype=np.float32)
            norm = float(np.linalg.norm(arr)) + 1e-12
            sample_embeddings.append((arr / norm).tolist())

        # Tính vector trung bình của các ảnh mẫu
        avg_vector = np.mean(np.array(sample_embeddings, dtype=np.float32), axis=0)

        # Chuẩn hóa L2 norm bắt buộc cho Master Template
        avg_norm = float(np.linalg.norm(avg_vector)) + 1e-12
        template_vector = (avg_vector / avg_norm).astype(np.float32)

        return {
            "template_embedding": template_vector.tolist(),
            "sample_count": len(sample_embeddings),
            "dimension": len(template_vector),
            "sample_embeddings": sample_embeddings,
        }

    def verify(
        self,
        probe_image_bytes: bytes,
        template_embedding: list[float],
        threshold: float = DEFAULT_MATCH_THRESHOLD,
    ) -> dict[str, Any]:
        """So khớp ảnh probe với Master Template embedding."""
        if not probe_image_bytes:
            raise ValueError("probe_image_bytes cannot be empty")
        if not template_embedding:
            raise ValueError("template_embedding cannot be empty")

        matched, similarity = self.client.verify_face(
            probe_image_bytes,
            template_embedding,
            threshold=threshold,
        )
        euclidean_dist = round(math.sqrt(max(0.0, 2.0 * (1.0 - similarity))), 4)
        match_confidence = compute_match_confidence(similarity)

        decision = "CÙNG MỘT NGƯỜI (MATCHED)" if matched else "KHÁC NGƯỜI (NOT MATCHED)"
        return {
            "matched": matched,
            "decision": decision,
            "similarity": round(similarity, 4),
            "match_confidence": match_confidence,
            "euclidean_distance": euclidean_dist,
            "threshold": threshold,
        }


def run_multi_sample_cli(
    enroll_dir: str,
    probe_path: str,
    target: str = DEFAULT_GRPC_ADDRESS,
    threshold: float = DEFAULT_MATCH_THRESHOLD,
) -> int:
    """CLI runner nạp ảnh mẫu từ thư mục và so khớp ảnh probe."""
    p_enroll = Path(enroll_dir)
    p_probe = Path(probe_path)

    if not p_enroll.is_dir():
        print(f"Lỗi: Thư mục đăng ký không tồn tại: {enroll_dir}", file=sys.stderr)
        return 1
    if not p_probe.is_file():
        print(f"Lỗi: File ảnh probe không tồn tại: {probe_path}", file=sys.stderr)
        return 1

    image_exts = {".jpg", ".jpeg", ".png", ".webp"}
    enroll_files = [f for f in sorted(p_enroll.iterdir()) if f.suffix.lower() in image_exts]
    if not enroll_files:
        print(f"Lỗi: Không tìm thấy ảnh hợp lệ trong {enroll_dir}", file=sys.stderr)
        return 1

    print(f"--- ĐĂNG KÝ KHUÔN MẶT ĐA MẪU ({len(enroll_files)} ẢNH) ---")
    enroll_bytes_list: list[bytes] = []
    for f in enroll_files:
        print(f"  + Nạp ảnh mẫu: {f.name}")
        enroll_bytes_list.append(f.read_bytes())

    probe_bytes = p_probe.read_bytes()

    client = FaceGrpcClient(target=target)
    try:
        service = MultiSampleEnrollmentService(client=client)
        print("\n--- Đang trích xuất và tính Master Template (L2 normalized) ---")
        enroll_res = service.enroll(enroll_bytes_list)
        print(f"  > Số chiều vector: {enroll_res['dimension']}")
        print(f"  > Số mẫu hợp nhất: {enroll_res['sample_count']}")

        print(f"\n--- NHẬN DIỆN ẢNH PROBE: {p_probe.name} ---")
        verify_res = service.verify(
            probe_bytes, enroll_res["template_embedding"], threshold=threshold
        )
        print(f"  > Kết quả: {verify_res['decision']}")
        print(f"  > Độ tương đồng Cosine: {verify_res['similarity']:.4f}")
        print(f"  > Độ tin cậy: {verify_res['match_confidence']}%")
        print(f"  > Ngưỡng so khớp: {verify_res['threshold']:.2f}")
        return 0 if verify_res["matched"] else 2
    finally:
        client.close()


def main() -> None:
    """Entry point hỗ trợ các chế độ chạy: HTTP Web UI hoặc gRPC Multi-Sample CLI."""
    parser = argparse.ArgumentParser(description="Face Recognition Test Server & Client")
    parser.add_argument("--serve", action="store_true", help="Chạy HTTP Server Web UI")
    parser.add_argument("--host", default="0.0.0.0", help="Host cho HTTP Server")
    parser.add_argument("--port", type=int, default=8000, help="Port cho HTTP Server")
    parser.add_argument("--grpc-target", default=DEFAULT_GRPC_ADDRESS, help="Địa chỉ gRPC server")
    parser.add_argument(
        "--threshold", type=float, default=DEFAULT_MATCH_THRESHOLD, help="Ngưỡng so khớp"
    )
    parser.add_argument("--enroll-dir", help="Thư mục chứa các ảnh mẫu đăng ký (3-5 ảnh)")
    parser.add_argument("--probe", help="Đường dẫn ảnh probe để nhận diện")

    args, _unknown = parser.parse_known_args()

    # Tương thích ngược: nếu truyền tham số đầu tiên là số nguyên port
    if len(sys.argv) > 1 and sys.argv[1].isdigit():
        run_http_server(host=args.host, port=int(sys.argv[1]))
        return

    if args.enroll_dir and args.probe:
        code = run_multi_sample_cli(
            enroll_dir=args.enroll_dir,
            probe_path=args.probe,
            target=args.grpc_target,
            threshold=args.threshold,
        )
        sys.exit(code)

    # Mặc định chạy HTTP Web UI
    run_http_server(host=args.host, port=args.port)


if __name__ == "__main__":
    main()
