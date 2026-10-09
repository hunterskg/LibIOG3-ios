"""Unit tests cho các entity trong domain."""

import pytest

from app.domain.entities.face import Face, FaceProfile
from app.domain.value_objects.bounding_box import BoundingBox
from app.domain.value_objects.embedding import FaceEmbedding
from app.domain.value_objects.landmark import FaceLandmarks, Point2D


def test_face_entity_initialization():
    """Kiểm tra khởi tạo Face với đúng kiểu dữ liệu."""
    bbox = BoundingBox(x=0.1, y=0.2, width=0.3, height=0.4, confidence=0.95)
    face = Face(id="test-face", bbox=bbox, confidence=0.95)
    assert face.id == "test-face"
    assert face.bbox.x == 0.1
    assert face.bbox.y == 0.2
    assert face.bbox.width == 0.3
    assert face.bbox.height == 0.4
    assert face.confidence == 0.95


def test_face_profile_initialization():
    """Kiểm tra khởi tạo FaceProfile."""
    embedding = FaceEmbedding(values=tuple([0.1] * 512), dimension=512)
    profile = FaceProfile(id="test-profile", embedding=embedding)
    assert profile.id == "test-profile"
    assert len(profile.embedding.values) == 512
    assert profile.embedding.dimension == 512


def test_face_landmarks_count():
    """Kiểm tra FaceLandmarks.count()."""
    landmarks = FaceLandmarks(
        points=(Point2D(x=1.0, y=2.0, index=1), Point2D(x=3.0, y=4.0, index=2))
    )
    assert landmarks.count() == 2


def test_face_landmarks_empty_count():
    """Kiểm tra FaceLandmarks.count() khi rỗng."""
    landmarks = FaceLandmarks(points=())
    assert landmarks.count() == 0


def test_face_embedding_validation():
    """Kiểm tra FaceEmbedding validation."""
    # Kiểm tra dimension đúng
    embedding = FaceEmbedding(values=tuple([0.0] * 512), dimension=512)
    assert embedding.dimension == 512
    assert len(embedding.values) == 512

    # Kiểm tra dimension sai
    with pytest.raises(ValueError):
        FaceEmbedding(values=tuple([0.0] * 511), dimension=512)


def test_face_quality_validation():
    """Kiểm tra quy tắc chất lượng ảnh (Laplacian variance, bbox, pitch/yaw/roll)."""
    from app.domain.exceptions.face_exceptions import LowFaceQualityException

    bbox = BoundingBox(x=0.1, y=0.2, width=100.0, height=110.0)

    # Đạt chuẩn: Laplacian variance >= 100, bbox >= 80x80, góc trong giới hạn
    good_face = Face(
        id="good-face",
        bbox=bbox,
        blur_score=150.0,
        pitch=5.0,
        yaw=-10.0,
        roll=3.0,
    )
    assert good_face.is_valid_quality() is True
    good_face.validate_quality()

    # Ảnh quá mờ: Laplacian variance < 100
    blurry_face = Face(id="blur-face", bbox=bbox, blur_score=50.0)
    assert blurry_face.is_valid_quality() is False
    with pytest.raises(LowFaceQualityException, match="quá mờ"):
        blurry_face.validate_quality()

    # Bbox quá nhỏ
    small_bbox = BoundingBox(x=0.1, y=0.2, width=40.0, height=40.0)
    small_face = Face(id="small-face", bbox=small_bbox, blur_score=150.0)
    assert small_face.is_valid_quality() is False
    with pytest.raises(LowFaceQualityException, match="quá nhỏ"):
        small_face.validate_quality()

    # Vượt góc pitch
    tilted_pitch_face = Face(id="pitch-face", bbox=bbox, pitch=35.0)
    assert tilted_pitch_face.is_valid_quality() is False
    with pytest.raises(LowFaceQualityException, match="pitch"):
        tilted_pitch_face.validate_quality()

    # Vượt góc yaw
    tilted_yaw_face = Face(id="yaw-face", bbox=bbox, yaw=-30.0)
    assert tilted_yaw_face.is_valid_quality() is False
    with pytest.raises(LowFaceQualityException, match="yaw"):
        tilted_yaw_face.validate_quality()

    # Vượt góc roll
    tilted_roll_face = Face(id="roll-face", bbox=bbox, roll=30.0)
    assert tilted_roll_face.is_valid_quality() is False
    with pytest.raises(LowFaceQualityException, match="roll"):
        tilted_roll_face.validate_quality()
