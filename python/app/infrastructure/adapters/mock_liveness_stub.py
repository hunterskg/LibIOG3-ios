from app.application.ports.liveness_detector import LivenessDetectorPort
from app.domain.entities.liveness import LivenessResult


class MockLivenessDetector(LivenessDetectorPort):
    """Adapter mock liveness trả về giá trị mẫu."""

    def __init__(self, default_confidence: float = 0.99) -> None:
        self._default_confidence = default_confidence

    def check_liveness(self, image_bytes: bytes) -> LivenessResult:
        raise NotImplementedError

    def _create_mock_result(self) -> LivenessResult:
        """Tạo kết quả mock mẫu cho test."""
        raise NotImplementedError
