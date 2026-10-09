"""Unit tests cho Mock Liveness Detector Adapter."""

import pytest

from app.application.ports.liveness_detector import LivenessDetectorPort
from app.infrastructure.adapters.mock_liveness_stub import MockLivenessDetector


def test_mock_liveness_detector_is_port():
    """Kiểm tra MockLivenessDetector triển khai LivenessDetectorPort."""
    detector = MockLivenessDetector(default_confidence=0.95)
    assert isinstance(detector, LivenessDetectorPort)


def test_mock_liveness_detector_methods():
    """Kiểm tra các method của MockLivenessDetector."""
    detector = MockLivenessDetector()
    with pytest.raises(NotImplementedError):
        detector.check_liveness(b"test_image")
    with pytest.raises(NotImplementedError):
        detector._create_mock_result()
