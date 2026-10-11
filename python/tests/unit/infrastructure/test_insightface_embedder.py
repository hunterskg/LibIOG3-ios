"""Unit tests cho InsightFaceEmbedder adapter."""

from unittest.mock import MagicMock

import cv2
import numpy as np
import pytest

from app.ports.face_detector import BoundingBox, FaceLandmarks, Point2D
from app.ports.face_embedder import FaceEmbedderPort
from app.infrastructure.adapters.insightface_embedder import InsightFaceEmbedder


@pytest.fixture
def sample_image_bytes() -> bytes:
    """Tạo bytes ảnh JPEG 150x150 hợp lệ dùng cho test."""
    img = np.zeros((150, 150, 3), dtype=np.uint8)
    success, buffer = cv2.imencode(".jpg", img)
    assert success
    return buffer.tobytes()


def test_insightface_embedder_implements_port():
    """Kiểm tra InsightFaceEmbedder implement FaceEmbedderPort."""
    embedder = InsightFaceEmbedder(recognizer=MagicMock())
    assert isinstance(embedder, FaceEmbedderPort)


def test_extract_embedding_raises_on_empty_bytes():
    """Kiểm tra ném ValueError khi truyền bytes rỗng."""
    embedder = InsightFaceEmbedder(recognizer=MagicMock())
    with pytest.raises(ValueError, match="Empty image bytes"):
        embedder.extract_embedding(b"")


def test_extract_embedding_raises_on_corrupted_image():
    """Kiểm tra ném ValueError khi ảnh bị hỏng."""
    embedder = InsightFaceEmbedder(recognizer=MagicMock())
    with pytest.raises(ValueError, match="Invalid or corrupted image format"):
        embedder.extract_embedding(b"not_a_valid_image")


def test_extract_embedding_crops_resizes_and_normalizes_l2(
    sample_image_bytes: bytes,
) -> None:
    """Kiểm tra crop bbox, resize 112x112, trích xuất raw 512-d và chuẩn hóa L2 norm."""
    mock_recognizer = MagicMock()
    # Vector thô 512 chiều có độ dài norm != 1
    raw_vector = np.full((512,), 2.0, dtype=np.float32)

    def fake_get_feat(face_img: np.ndarray) -> np.ndarray:
        # Kiểm tra ảnh đầu vào recognizer đã được resize chuẩn 112x112x3
        assert face_img.shape == (112, 112, 3)
        return raw_vector

    mock_recognizer.get_feat.side_effect = fake_get_feat
    embedder = InsightFaceEmbedder(recognizer=mock_recognizer)

    bbox = BoundingBox(x=10.0, y=10.0, width=50.0, height=60.0)
    embedding = embedder.extract_embedding(sample_image_bytes, bbox=bbox)

    assert embedding.dimension == 512
    assert len(embedding.values) == 512

    # Kiểm tra chuẩn hóa L2 norm: tổng bình phương xấp xỉ 1.0
    l2_norm = float(np.linalg.norm(np.array(embedding.values)))
    assert pytest.approx(l2_norm, abs=1e-5) == 1.0

    expected_element = 1.0 / np.sqrt(512)
    assert pytest.approx(embedding.values[0], abs=1e-5) == expected_element


def test_extract_embedding_without_bbox(sample_image_bytes: bytes) -> None:
    """Kiểm tra trích xuất embedding không kèm bbox (resize toàn bộ ảnh)."""
    mock_recognizer = MagicMock()
    mock_recognizer.get_feat.return_value = np.ones((512,), dtype=np.float32)
    embedder = InsightFaceEmbedder(recognizer=mock_recognizer)

    embedding = embedder.extract_embedding(sample_image_bytes, bbox=None)
    assert embedding.dimension == 512


def test_extract_embedding_with_landmarks_aligns_face(sample_image_bytes: bytes) -> None:
    """Kiểm tra trích xuất embedding với 5 landmarks căn chỉnh ArcFace 112x112 qua cv2."""
    import warnings

    from app.ports.face_detector import FaceLandmarks, Point2D
    from app.infrastructure.adapters.insightface_embedder import ARCFACE_DST_112

    mock_recognizer = MagicMock()
    raw_vector = np.ones((512,), dtype=np.float32)

    def fake_get_feat(face_img: np.ndarray) -> np.ndarray:
        assert face_img.shape == (112, 112, 3)
        return raw_vector

    mock_recognizer.get_feat.side_effect = fake_get_feat
    embedder = InsightFaceEmbedder(recognizer=mock_recognizer)

    landmarks = FaceLandmarks(
        points=(
            Point2D(x=30.0, y=30.0, index=0),
            Point2D(x=70.0, y=30.0, index=1),
            Point2D(x=50.0, y=50.0, index=2),
            Point2D(x=35.0, y=70.0, index=3),
            Point2D(x=65.0, y=70.0, index=4),
        )
    )

    with warnings.catch_warnings():
        warnings.simplefilter("error", FutureWarning)
        embedding = embedder.extract_embedding(sample_image_bytes, landmarks=landmarks)

    assert embedding.dimension == 512
    assert mock_recognizer.get_feat.called
    assert len(embedding.values) == 512

    # Kiểm tra ma trận chuẩn ArcFace 112x112 và L2 norm = 1.0
    assert ARCFACE_DST_112.shape == (5, 2)
    assert ARCFACE_DST_112.dtype == np.float32
    l2_norm = float(np.linalg.norm(np.array(embedding.values)))
    assert pytest.approx(l2_norm, abs=1e-5) == 1.0


def test_extract_embedding_raises_on_dimension_mismatch(sample_image_bytes: bytes) -> None:
    """Kiểm tra ném ValueError khi recognizer trả vector không đúng 512 chiều."""
    mock_recognizer = MagicMock()
    mock_recognizer.get_feat.return_value = np.ones((128,), dtype=np.float32)
    embedder = InsightFaceEmbedder(recognizer=mock_recognizer)

    with pytest.raises(ValueError, match="does not match 512"):
        embedder.extract_embedding(sample_image_bytes)
