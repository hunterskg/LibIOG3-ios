"""Unit tests cho InsightFaceDetector adapter."""

from unittest.mock import MagicMock

import cv2
import numpy as np
import pytest

from app.ports.face_detector import FaceDetectorPort
from app.infrastructure.adapters.insightface_detector import InsightFaceDetector


@pytest.fixture
def sample_image_bytes() -> bytes:
    """Tạo bytes ảnh JPEG hợp lệ 100x100 dùng cho test."""
    img = np.zeros((100, 100, 3), dtype=np.uint8)
    success, buffer = cv2.imencode(".jpg", img)
    assert success
    return buffer.tobytes()


def test_insightface_detector_implements_port():
    """Kiểm tra InsightFaceDetector implement FaceDetectorPort."""
    detector = InsightFaceDetector(app=MagicMock())
    assert isinstance(detector, FaceDetectorPort)


def test_detect_raises_on_empty_bytes():
    """Kiểm tra ném ValueError khi truyền bytes rỗng."""
    detector = InsightFaceDetector(app=MagicMock())
    with pytest.raises(ValueError, match="Empty image bytes"):
        detector.detect(b"")


def test_detect_raises_on_invalid_image_bytes():
    """Kiểm tra ném ValueError khi ảnh bị hỏng hoặc không decode được."""
    detector = InsightFaceDetector(app=MagicMock())
    with pytest.raises(ValueError, match="Invalid or corrupted image format"):
        detector.detect(b"not_an_image_binary_data")


def test_detect_maps_face_attributes_correctly(sample_image_bytes: bytes) -> None:
    """Kiểm tra mock app phân tích và map BoundingBox, landmarks, pose sang Face entity."""
    mock_app = MagicMock()
    mock_raw_face = MagicMock()
    mock_raw_face.bbox = [10.0, 20.0, 50.0, 80.0]
    mock_raw_face.det_score = 0.95
    mock_raw_face.kps = [
        [15.0, 25.0],
        [45.0, 25.0],
        [30.0, 50.0],
        [20.0, 70.0],
        [40.0, 70.0],
    ]
    mock_raw_face.pose = [5.0, -2.0, 1.0]

    mock_app.get.return_value = [mock_raw_face]
    detector = InsightFaceDetector(app=mock_app)

    faces = detector.detect(sample_image_bytes)

    assert len(faces) == 1
    face = faces[0]

    assert face.confidence == 0.95
    assert face.bbox.x == 10.0
    assert face.bbox.y == 20.0
    assert face.bbox.width == 40.0
    assert face.bbox.height == 60.0

    assert face.landmarks is not None
    assert len(face.landmarks.points) == 5
    assert face.landmarks.points[0].x == 15.0
    assert face.landmarks.points[0].y == 25.0
    assert face.landmarks.points[0].index == 0

    assert face.pitch == 5.0
    assert face.yaw == -2.0
    assert face.roll == 1.0


def test_detect_dict_face_and_fallback_score(sample_image_bytes: bytes) -> None:
    """Kiểm tra xử lý raw face dạng dict và fallback score khi det_score None."""
    mock_app = MagicMock()
    dict_face = {
        "bbox": [5.0, 5.0, 25.0, 35.0],
        "det_score": None,
        "score": 0.88,
        "kps": None,
        "pitch": 2.5,
        "yaw": -1.5,
        "roll": 0.5,
    }
    mock_app.get.return_value = [dict_face]
    detector = InsightFaceDetector(app=mock_app)

    faces = detector.detect(sample_image_bytes)

    assert len(faces) == 1
    face = faces[0]
    assert face.confidence == 0.88
    assert face.bbox.x == 5.0
    assert face.bbox.y == 5.0
    assert face.bbox.width == 20.0
    assert face.bbox.height == 30.0
    assert face.landmarks is None
    assert face.pitch == 2.5
    assert face.yaw == -1.5
    assert face.roll == 0.5


def test_detect_skips_item_without_bbox(sample_image_bytes: bytes) -> None:
    """Kiểm tra bỏ qua phần tử không có bounding box."""
    mock_app = MagicMock()
    invalid_face = {"bbox": None, "score": 0.9}
    mock_app.get.return_value = [invalid_face]
    detector = InsightFaceDetector(app=mock_app)

    faces = detector.detect(sample_image_bytes)
    assert len(faces) == 0


def test_detect_computes_laplacian_blur_score(sample_image_bytes: bytes) -> None:
    """Kiểm tra detector tính blur_score (Laplacian variance) trên vùng crop khuôn mặt."""
    mock_app = MagicMock()
    mock_raw_face = MagicMock()
    mock_raw_face.bbox = [10.0, 20.0, 50.0, 80.0]
    mock_raw_face.det_score = 0.95
    mock_raw_face.kps = None
    mock_raw_face.pose = [5.0, -2.0, 1.0]
    mock_raw_face.pitch = None
    mock_raw_face.yaw = None
    mock_raw_face.roll = None

    mock_app.get.return_value = [mock_raw_face]
    detector = InsightFaceDetector(app=mock_app)

    faces = detector.detect(sample_image_bytes)

    assert len(faces) == 1
    face = faces[0]
    # Ảnh test toàn màu đen -> Laplacian variance = 0.0
    assert face.blur_score is not None
    assert isinstance(face.blur_score, float)
    assert face.blur_score >= 0.0


def test_detect_blur_score_on_textured_image() -> None:
    """Kiểm tra blur_score khác nhau giữa ảnh chi tiết và ảnh mượt."""
    rng = np.random.default_rng(42)
    textured = rng.integers(0, 256, size=(100, 100, 3), dtype=np.uint8)
    success, buffer = cv2.imencode(".jpg", textured)
    assert success
    textured_bytes = buffer.tobytes()

    mock_app = MagicMock()
    mock_raw_face = MagicMock()
    mock_raw_face.bbox = [10.0, 10.0, 90.0, 90.0]
    mock_raw_face.det_score = 0.9
    mock_raw_face.kps = None
    mock_raw_face.pose = [0.0, 0.0, 0.0]
    mock_app.get.return_value = [mock_raw_face]
    detector = InsightFaceDetector(app=mock_app)

    faces = detector.detect(textured_bytes)
    assert len(faces) == 1
    assert faces[0].blur_score is not None
    assert faces[0].blur_score is not None and faces[0].blur_score > 0.0
