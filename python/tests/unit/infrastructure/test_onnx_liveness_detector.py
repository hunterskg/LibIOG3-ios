"""Unit tests cho OnnxLivenessDetector adapter."""

from unittest.mock import MagicMock

import cv2
import numpy as np
import pytest

from app.ports.liveness_detector import LivenessDetectorPort, LivenessStatus
from app.infrastructure.adapters.onnx_liveness_detector import OnnxLivenessDetector


@pytest.fixture
def sample_image_bytes() -> bytes:
    """Tạo bytes ảnh JPEG 120x120 hợp lệ dùng cho test."""
    img = np.zeros((120, 120, 3), dtype=np.uint8)
    success, buffer = cv2.imencode(".jpg", img)
    assert success
    return buffer.tobytes()


def test_onnx_liveness_detector_implements_port():
    """Kiểm tra OnnxLivenessDetector implement LivenessDetectorPort."""
    detector = OnnxLivenessDetector(session=MagicMock())
    assert isinstance(detector, LivenessDetectorPort)


def test_check_liveness_raises_on_empty_bytes():
    """Kiểm tra ném ValueError khi truyền bytes rỗng."""
    detector = OnnxLivenessDetector(session=MagicMock())
    with pytest.raises(ValueError, match="Empty image bytes"):
        detector.check_liveness(b"")


def test_check_liveness_raises_on_corrupted_image():
    """Kiểm tra ném ValueError khi ảnh bị hỏng."""
    detector = OnnxLivenessDetector(session=MagicMock())
    with pytest.raises(ValueError, match="Invalid or corrupted image format"):
        detector.check_liveness(b"corrupted_bytes")


def test_check_liveness_nchw_preprocessing_and_real_classification(
    sample_image_bytes: bytes,
) -> None:
    """Kiểm tra tiền xử lý NCHW (1, 3, 80, 80), softmax và phân loại REAL khi score >= threshold."""
    mock_session = MagicMock()
    mock_input_node = MagicMock()
    mock_input_node.name = "input_tensor"
    mock_session.get_inputs.return_value = [mock_input_node]

    # Giả lập logits [spoof_logit, real_logit] với real_logit vượt trội
    mock_session.run.return_value = [np.array([[0.0, 5.0]], dtype=np.float32)]

    detector = OnnxLivenessDetector(
        threshold=0.80,
        input_size=(80, 80),
        session=mock_session,
    )
    result = detector.check_liveness(sample_image_bytes)

    # Kiểm tra tensor đầu vào truyền tới session.run
    mock_session.run.assert_called_once()
    call_args = mock_session.run.call_args[0]
    feed_dict = call_args[1]
    assert "input_tensor" in feed_dict
    tensor = feed_dict["input_tensor"]
    assert tensor.shape == (1, 3, 80, 80)
    assert tensor.dtype == np.float32
    assert np.all(tensor >= 0.0) and np.all(tensor <= 1.0)

    # Kiểm tra kết quả
    assert result.is_live is True
    assert result.status == LivenessStatus.REAL
    assert result.confidence >= 0.80
    assert result.details is not None
    assert result.details["threshold"] == 0.80


def test_check_liveness_spoof_classification(sample_image_bytes: bytes) -> None:
    """Kiểm tra phân loại SPOOF khi softmax score < threshold."""
    mock_session = MagicMock()
    mock_session.get_inputs.return_value = []
    # Giả lập logits với spoof_logit vượt trội
    mock_session.run.return_value = [np.array([[5.0, 0.0]], dtype=np.float32)]

    detector = OnnxLivenessDetector(
        threshold=0.80,
        input_size=(80, 80),
        session=mock_session,
    )
    result = detector.check_liveness(sample_image_bytes)

    assert result.is_live is False
    assert result.status == LivenessStatus.SPOOF
    assert result.confidence < 0.80


def test_check_liveness_single_scalar_output(sample_image_bytes: bytes) -> None:
    """Kiểm tra khi model trả về single score scalar."""
    mock_session = MagicMock()
    mock_session.get_inputs.return_value = []
    mock_session.run.return_value = [np.array([0.92], dtype=np.float32)]

    detector = OnnxLivenessDetector(
        threshold=0.80,
        session=mock_session,
    )
    result = detector.check_liveness(sample_image_bytes)

    assert result.is_live is True
    assert result.status == LivenessStatus.REAL
    assert pytest.approx(result.confidence, abs=1e-5) == 0.92
