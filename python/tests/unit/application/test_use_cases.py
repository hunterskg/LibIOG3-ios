"""Unit tests cho các Application Use Cases."""

import pytest

from app.application.use_cases.check_liveness import CheckLivenessUseCase
from app.application.use_cases.detect_face import DetectFaceUseCase
from app.application.use_cases.extract_embedding import ExtractEmbeddingUseCase
from app.application.use_cases.verify_face import VerifyFaceUseCase
from app.domain.entities.face import Face
from app.domain.entities.liveness import LivenessResult, LivenessStatus
from app.domain.exceptions.face_exceptions import (
    EmbeddingMismatchException,
    FaceNotFoundException,
    LowFaceQualityException,
    MultipleFacesDetectedException,
    SpoofDetectedException,
)
from app.domain.value_objects.bounding_box import BoundingBox
from app.domain.value_objects.embedding import FaceEmbedding


def _create_valid_face(face_id: str = "face-1") -> Face:
    """Tạo đối tượng Face hợp lệ cho test."""
    bbox = BoundingBox(x=10.0, y=10.0, width=100.0, height=100.0, confidence=0.95)
    return Face(
        id=face_id,
        bbox=bbox,
        landmarks=None,
        confidence=0.95,
        blur_score=150.0,
        pitch=5.0,
        yaw=5.0,
        roll=2.0,
    )


# =====================================================================
# DetectFaceUseCase Tests
# =====================================================================


def test_detect_face_empty_image_raises_value_error(mock_detector):
    """DetectFace ném ValueError khi image_bytes rỗng."""
    uc = DetectFaceUseCase(detector=mock_detector)
    with pytest.raises(ValueError, match="image_bytes is required"):
        uc.execute(b"")


def test_detect_face_respects_max_faces(mock_detector):
    """DetectFace giới hạn số lượng kết quả theo max_faces."""
    face1 = _create_valid_face("f1")
    face2 = _create_valid_face("f2")
    face3 = _create_valid_face("f3")
    mock_detector.detect.return_value = [face1, face2, face3]

    uc = DetectFaceUseCase(detector=mock_detector)
    results = uc.execute(b"valid_image", max_faces=2)

    assert len(results) == 2
    assert results == [face1, face2]


def test_detect_face_returns_all_when_max_faces_non_positive(mock_detector):
    """DetectFace trả về toàn bộ khuôn mặt khi max_faces <= 0."""
    face1 = _create_valid_face("f1")
    face2 = _create_valid_face("f2")
    mock_detector.detect.return_value = [face1, face2]

    uc = DetectFaceUseCase(detector=mock_detector)
    results = uc.execute(b"valid_image", max_faces=0)

    assert len(results) == 2


# =====================================================================
# CheckLivenessUseCase Tests
# =====================================================================


def test_check_liveness_empty_image_raises_value_error(mock_liveness_detector):
    """CheckLiveness ném ValueError khi image_bytes rỗng."""
    uc = CheckLivenessUseCase(liveness_detector=mock_liveness_detector)
    with pytest.raises(ValueError, match="image_bytes is required"):
        uc.execute(b"")


def test_check_liveness_without_detector_success(mock_liveness_detector):
    """CheckLiveness hoạt động bình thường khi không truyền detector."""
    expected = LivenessResult(
        is_live=True,
        status=LivenessStatus.REAL,
        confidence=0.98,
        details={},
    )
    mock_liveness_detector.check_liveness.return_value = expected

    uc = CheckLivenessUseCase(liveness_detector=mock_liveness_detector)
    result = uc.execute(b"valid_image")

    assert result == expected
    mock_liveness_detector.check_liveness.assert_called_once_with(b"valid_image")


def test_check_liveness_with_detector_no_face_raises_exception(
    mock_liveness_detector, mock_detector
):
    """CheckLiveness ném FaceNotFoundException khi detector không thấy khuôn mặt."""
    mock_detector.detect.return_value = []
    uc = CheckLivenessUseCase(liveness_detector=mock_liveness_detector, detector=mock_detector)

    with pytest.raises(FaceNotFoundException, match="No face detected for liveness check"):
        uc.execute(b"valid_image")


def test_check_liveness_with_detector_face_found_success(mock_liveness_detector, mock_detector):
    """CheckLiveness thành công khi detector phát hiện khuôn mặt."""
    mock_detector.detect.return_value = [_create_valid_face()]
    expected = LivenessResult(
        is_live=True,
        status=LivenessStatus.REAL,
        confidence=0.99,
    )
    mock_liveness_detector.check_liveness.return_value = expected

    uc = CheckLivenessUseCase(liveness_detector=mock_liveness_detector, detector=mock_detector)
    result = uc.execute(b"valid_image")

    assert result == expected
    mock_detector.detect.assert_called_once_with(b"valid_image")
    mock_liveness_detector.check_liveness.assert_called_once_with(b"valid_image")


# =====================================================================
# ExtractEmbeddingUseCase Tests
# =====================================================================


def test_extract_embedding_empty_image_raises_value_error(mock_embedder):
    """ExtractEmbedding ném ValueError khi image_bytes rỗng."""
    uc = ExtractEmbeddingUseCase(embedder=mock_embedder)
    with pytest.raises(ValueError, match="image_bytes is required"):
        uc.execute(b"")


def test_extract_embedding_no_face_detected_raises_exception(mock_embedder, mock_detector):
    """ExtractEmbedding ném FaceNotFoundException khi không tìm thấy khuôn mặt."""
    mock_detector.detect.return_value = []
    uc = ExtractEmbeddingUseCase(embedder=mock_embedder, detector=mock_detector)

    with pytest.raises(FaceNotFoundException, match="No face detected in image"):
        uc.execute(b"valid_image")


def test_extract_embedding_multiple_faces_raises_exception(mock_embedder, mock_detector):
    """ExtractEmbedding ném MultipleFacesDetectedException khi phát hiện nhiều hơn 1 mặt."""
    mock_detector.detect.return_value = [_create_valid_face("f1"), _create_valid_face("f2")]
    uc = ExtractEmbeddingUseCase(
        embedder=mock_embedder,
        detector=mock_detector,
        require_single_face=True,
    )

    with pytest.raises(MultipleFacesDetectedException, match="Expected single face, detected 2"):
        uc.execute(b"valid_image")


def test_extract_embedding_multiple_faces_allowed_when_single_not_required(
    mock_embedder, mock_detector
):
    """ExtractEmbedding chọn mặt đầu tiên khi require_single_face=False."""
    face1 = _create_valid_face("f1")
    face2 = _create_valid_face("f2")
    mock_detector.detect.return_value = [face1, face2]

    expected_emb = FaceEmbedding(values=tuple([0.1] * 512), dimension=512)
    mock_embedder.extract_embedding.return_value = expected_emb

    uc = ExtractEmbeddingUseCase(
        embedder=mock_embedder,
        detector=mock_detector,
        require_single_face=False,
    )
    result = uc.execute(b"valid_image")

    assert result == expected_emb.l2_normalize()
    mock_embedder.extract_embedding.assert_called_once_with(b"valid_image", bbox=face1.bbox)


def test_extract_embedding_low_quality_raises_exception(mock_embedder, mock_detector):
    """ExtractEmbedding ném LowFaceQualityException khi ảnh quá mờ."""
    bad_face = _create_valid_face()
    bad_face.blur_score = 0.9  # > DEFAULT_MAX_BLUR (0.5)
    mock_detector.detect.return_value = [bad_face]

    uc = ExtractEmbeddingUseCase(
        embedder=mock_embedder,
        detector=mock_detector,
        validate_quality=True,
    )
    with pytest.raises(LowFaceQualityException):
        uc.execute(b"valid_image")


def test_extract_embedding_ignores_quality_when_flag_false(mock_embedder, mock_detector):
    """ExtractEmbedding bỏ qua kiểm tra chất lượng khi validate_quality=False."""
    bad_face = _create_valid_face()
    bad_face.blur_score = 0.9
    mock_detector.detect.return_value = [bad_face]

    expected_emb = FaceEmbedding(values=tuple([0.1] * 512), dimension=512)
    mock_embedder.extract_embedding.return_value = expected_emb

    uc = ExtractEmbeddingUseCase(
        embedder=mock_embedder,
        detector=mock_detector,
        validate_quality=False,
    )
    result = uc.execute(b"valid_image")

    assert result == expected_emb.l2_normalize()


def test_extract_embedding_spoof_detected_raises_exception(
    mock_embedder, mock_detector, mock_liveness_detector
):
    """ExtractEmbedding ném SpoofDetectedException khi liveness trả về giả mạo."""
    mock_detector.detect.return_value = [_create_valid_face()]
    mock_liveness_detector.check_liveness.return_value = LivenessResult(
        is_live=False,
        status=LivenessStatus.SPOOF,
        confidence=0.92,
    )

    uc = ExtractEmbeddingUseCase(
        embedder=mock_embedder,
        detector=mock_detector,
        liveness_detector=mock_liveness_detector,
    )
    with pytest.raises(SpoofDetectedException, match="Spoof detected with confidence 0.92"):
        uc.execute(b"valid_image")


def test_extract_embedding_direct_bbox_bypasses_detector(mock_embedder, mock_detector):
    """ExtractEmbedding sử dụng bbox truyền vào trực tiếp và bỏ qua detector."""
    custom_bbox = BoundingBox(x=5.0, y=5.0, width=40.0, height=40.0)
    expected_emb = FaceEmbedding(values=tuple([0.2] * 512), dimension=512)
    mock_embedder.extract_embedding.return_value = expected_emb

    uc = ExtractEmbeddingUseCase(embedder=mock_embedder, detector=mock_detector)
    result = uc.execute(b"valid_image", bbox=custom_bbox)

    assert result == expected_emb.l2_normalize()
    mock_detector.detect.assert_not_called()
    mock_embedder.extract_embedding.assert_called_once_with(b"valid_image", bbox=custom_bbox)


def test_extract_embedding_full_pipeline_success(
    mock_embedder, mock_detector, mock_liveness_detector
):
    """ExtractEmbedding vượt qua toàn bộ pipeline Detector -> Liveness -> Embedder thành công."""
    valid_face = _create_valid_face()
    mock_detector.detect.return_value = [valid_face]
    mock_liveness_detector.check_liveness.return_value = LivenessResult(
        is_live=True,
        status=LivenessStatus.REAL,
        confidence=0.99,
    )
    expected_emb = FaceEmbedding(values=tuple([0.5] * 512), dimension=512)
    mock_embedder.extract_embedding.return_value = expected_emb

    uc = ExtractEmbeddingUseCase(
        embedder=mock_embedder,
        detector=mock_detector,
        liveness_detector=mock_liveness_detector,
    )
    result = uc.execute(b"valid_image")

    assert result == expected_emb.l2_normalize()
    mock_detector.detect.assert_called_once_with(b"valid_image")
    mock_liveness_detector.check_liveness.assert_called_once_with(b"valid_image")
    mock_embedder.extract_embedding.assert_called_once_with(b"valid_image", bbox=valid_face.bbox)


# =====================================================================
# VerifyFaceUseCase Tests
# =====================================================================


def test_verify_face_empty_image_raises_value_error(mock_embedder, mock_similarity):
    """VerifyFace ném ValueError khi image_bytes rỗng."""
    ref_emb = FaceEmbedding(values=tuple([0.1] * 512), dimension=512)
    uc = VerifyFaceUseCase(embedder=mock_embedder, similarity_calculator=mock_similarity)
    with pytest.raises(ValueError, match="image_bytes is required"):
        uc.execute(b"", reference_embedding=ref_emb)


def test_verify_face_no_face_detected_raises_exception(
    mock_embedder, mock_similarity, mock_detector
):
    """VerifyFace ném FaceNotFoundException khi detector không phát hiện khuôn mặt."""
    mock_detector.detect.return_value = []
    ref_emb = FaceEmbedding(values=tuple([0.1] * 512), dimension=512)

    uc = VerifyFaceUseCase(
        embedder=mock_embedder,
        similarity_calculator=mock_similarity,
        detector=mock_detector,
    )
    with pytest.raises(FaceNotFoundException, match="No face detected for verification"):
        uc.execute(b"valid_image", reference_embedding=ref_emb)


def test_verify_face_multiple_faces_detected_raises_exception(
    mock_embedder, mock_similarity, mock_detector
):
    """VerifyFace ném MultipleFacesDetectedException khi phát hiện >1 mặt."""
    mock_detector.detect.return_value = [_create_valid_face("f1"), _create_valid_face("f2")]
    ref_emb = FaceEmbedding(values=tuple([0.1] * 512), dimension=512)

    uc = VerifyFaceUseCase(
        embedder=mock_embedder,
        similarity_calculator=mock_similarity,
        detector=mock_detector,
    )
    with pytest.raises(
        MultipleFacesDetectedException,
        match="Expected single face for verification, detected 2",
    ):
        uc.execute(b"valid_image", reference_embedding=ref_emb)


def test_verify_face_low_quality_raises_exception(mock_embedder, mock_similarity, mock_detector):
    """VerifyFace ném LowFaceQualityException khi ảnh chất lượng kém."""
    bad_face = _create_valid_face()
    bad_face.pitch = 45.0  # > max_pitch (thường là 30.0)
    mock_detector.detect.return_value = [bad_face]
    ref_emb = FaceEmbedding(values=tuple([0.1] * 512), dimension=512)

    uc = VerifyFaceUseCase(
        embedder=mock_embedder,
        similarity_calculator=mock_similarity,
        detector=mock_detector,
        validate_quality=True,
    )
    with pytest.raises(LowFaceQualityException):
        uc.execute(b"valid_image", reference_embedding=ref_emb)


def test_verify_face_spoof_detected_raises_exception(
    mock_embedder, mock_similarity, mock_detector, mock_liveness_detector
):
    """VerifyFace ném SpoofDetectedException khi liveness phát hiện giả mạo."""
    mock_detector.detect.return_value = [_create_valid_face()]
    mock_liveness_detector.check_liveness.return_value = LivenessResult(
        is_live=False,
        status=LivenessStatus.SPOOF,
        confidence=0.88,
    )
    ref_emb = FaceEmbedding(values=tuple([0.1] * 512), dimension=512)

    uc = VerifyFaceUseCase(
        embedder=mock_embedder,
        similarity_calculator=mock_similarity,
        detector=mock_detector,
        liveness_detector=mock_liveness_detector,
    )
    with pytest.raises(
        SpoofDetectedException,
        match="Spoof detected during verification with confidence 0.88",
    ):
        uc.execute(b"valid_image", reference_embedding=ref_emb)


def test_verify_face_dimension_mismatch_raises_exception(mock_embedder, mock_similarity):
    """VerifyFace ném EmbeddingMismatchException khi khác số chiều."""
    candidate_emb = FaceEmbedding(values=tuple([0.1] * 512), dimension=512)
    mock_embedder.extract_embedding.return_value = candidate_emb
    ref_emb = FaceEmbedding(values=tuple([0.1] * 256), dimension=256)

    uc = VerifyFaceUseCase(embedder=mock_embedder, similarity_calculator=mock_similarity)
    with pytest.raises(
        EmbeddingMismatchException,
        match="Embedding dimension mismatch: candidate 512 vs reference 256",
    ):
        uc.execute(b"valid_image", reference_embedding=ref_emb)


def test_verify_face_success_matched(
    mock_embedder, mock_similarity, mock_detector, mock_liveness_detector
):
    """VerifyFace xác thực thành công khi similarity >= threshold."""
    valid_face = _create_valid_face()
    mock_detector.detect.return_value = [valid_face]
    mock_liveness_detector.check_liveness.return_value = LivenessResult(
        is_live=True,
        status=LivenessStatus.REAL,
        confidence=0.99,
    )
    candidate_emb = FaceEmbedding(values=tuple([0.5] * 512), dimension=512)
    ref_emb = FaceEmbedding(values=tuple([0.5] * 512), dimension=512)
    mock_embedder.extract_embedding.return_value = candidate_emb
    mock_similarity.compute_cosine_similarity.return_value = 0.85

    uc = VerifyFaceUseCase(
        embedder=mock_embedder,
        similarity_calculator=mock_similarity,
        detector=mock_detector,
        liveness_detector=mock_liveness_detector,
    )
    matched, score = uc.execute(b"valid_image", reference_embedding=ref_emb, threshold=0.65)

    assert matched is True
    assert score == pytest.approx(0.85)


def test_verify_face_success_not_matched(mock_embedder, mock_similarity):
    """VerifyFace trả về matched=False khi similarity < threshold."""
    candidate_emb = FaceEmbedding(values=tuple([0.1] * 512), dimension=512)
    ref_emb = FaceEmbedding(values=tuple([0.9] * 512), dimension=512)
    mock_embedder.extract_embedding.return_value = candidate_emb
    mock_similarity.compute_cosine_similarity.return_value = 0.40

    uc = VerifyFaceUseCase(embedder=mock_embedder, similarity_calculator=mock_similarity)
    matched, score = uc.execute(b"valid_image", reference_embedding=ref_emb, threshold=0.65)

    assert matched is False
    assert score == pytest.approx(0.40)


def test_verify_face_direct_bbox_bypasses_detector(mock_embedder, mock_similarity, mock_detector):
    """VerifyFace sử dụng bbox trực tiếp và không gọi detector."""
    custom_bbox = BoundingBox(x=10.0, y=10.0, width=30.0, height=30.0)
    candidate_emb = FaceEmbedding(values=tuple([0.5] * 512), dimension=512)
    ref_emb = FaceEmbedding(values=tuple([0.5] * 512), dimension=512)
    mock_embedder.extract_embedding.return_value = candidate_emb
    mock_similarity.compute_cosine_similarity.return_value = 0.90

    uc = VerifyFaceUseCase(
        embedder=mock_embedder,
        similarity_calculator=mock_similarity,
        detector=mock_detector,
    )
    matched, _score = uc.execute(
        b"valid_image",
        reference_embedding=ref_emb,
        bbox=custom_bbox,
        threshold=0.65,
    )

    assert matched is True
    assert _score == pytest.approx(0.90)
    mock_detector.detect.assert_not_called()
    mock_embedder.extract_embedding.assert_called_once_with(b"valid_image", bbox=custom_bbox)
