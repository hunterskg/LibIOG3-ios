"""Unit tests cho logic warmup() của 3 adapters."""

from unittest.mock import MagicMock

import numpy as np

from app.infrastructure.adapters.insightface_detector import InsightFaceDetector
from app.infrastructure.adapters.insightface_embedder import InsightFaceEmbedder
from app.infrastructure.adapters.onnx_liveness_detector import OnnxLivenessDetector


def test_insightface_detector_warmup() -> None:
    """Kiểm tra InsightFaceDetector.warmup gọi app.get với dummy frame."""
    mock_app = MagicMock()
    detector = InsightFaceDetector(app=mock_app)

    detector.warmup()

    mock_app.get.assert_called_once()
    called_arg = mock_app.get.call_args[0][0]
    assert isinstance(called_arg, np.ndarray)
    assert called_arg.shape == (640, 640, 3)
    assert called_arg.dtype == np.uint8


def test_insightface_embedder_warmup_with_get_feat() -> None:
    """Kiểm tra InsightFaceEmbedder.warmup ưu tiên get_feat khi có sẵn."""
    mock_rec = MagicMock()
    embedder = InsightFaceEmbedder(recognizer=mock_rec)

    embedder.warmup()

    mock_rec.get_feat.assert_called_once()
    called_arg = mock_rec.get_feat.call_args[0][0]
    assert isinstance(called_arg, np.ndarray)
    assert called_arg.shape == (112, 112, 3)
    assert called_arg.dtype == np.uint8


def test_insightface_embedder_warmup_with_get_fallback() -> None:
    """Kiểm tra InsightFaceEmbedder.warmup fallback sang get khi không có get_feat."""
    mock_rec = MagicMock(spec=["get"])
    embedder = InsightFaceEmbedder(recognizer=mock_rec)

    embedder.warmup()

    mock_rec.get.assert_called_once()
    called_arg = mock_rec.get.call_args[0][0]
    assert isinstance(called_arg, np.ndarray)
    assert called_arg.shape == (112, 112, 3)


def test_insightface_embedder_warmup_callable_fallback() -> None:
    """Kiểm tra InsightFaceEmbedder.warmup fallback sang gọi trực tiếp nếu callable."""
    mock_rec = MagicMock(spec=[])
    embedder = InsightFaceEmbedder(recognizer=mock_rec)

    embedder.warmup()

    mock_rec.assert_called_once()
    called_arg = mock_rec.call_args[0][0]
    assert isinstance(called_arg, np.ndarray)
    assert called_arg.shape == (112, 112, 3)


def test_onnx_liveness_detector_warmup_with_named_input() -> None:
    """Kiểm tra OnnxLivenessDetector.warmup chạy dummy inference với dynamic input name."""
    mock_session = MagicMock()
    mock_input = MagicMock()
    mock_input.name = "custom_tensor_input"
    mock_session.get_inputs.return_value = [mock_input]

    detector = OnnxLivenessDetector(session=mock_session, input_size=(80, 80))
    detector.warmup()

    mock_session.run.assert_called_once()
    call_args = mock_session.run.call_args
    assert call_args[0][0] is None
    feed_dict = call_args[0][1]
    assert "custom_tensor_input" in feed_dict
    tensor = feed_dict["custom_tensor_input"]
    assert tensor.shape == (1, 3, 80, 80)
    assert tensor.dtype == np.float32


def test_onnx_liveness_detector_warmup_with_default_input_name() -> None:
    """Kiểm tra OnnxLivenessDetector.warmup fallback tên input sang 'input'."""
    mock_session = MagicMock(spec=["run"])
    detector = OnnxLivenessDetector(session=mock_session, input_size=(112, 112))

    detector.warmup()

    mock_session.run.assert_called_once()
    feed_dict = mock_session.run.call_args[0][1]
    assert "input" in feed_dict
    assert feed_dict["input"].shape == (1, 3, 112, 112)
