from app.application.ports.liveness_detector import LivenessDetectorPort
from app.domain.entities.liveness import LivenessResult


class OnnxLivenessDetectorStub(LivenessDetectorPort):
    """Adapter stub cho LivenessDetectorPort dựa trên ONNX (không logic chi tiết)."""

    def __init__(self, model_path: str = "models/liveness.onnx", threshold: float = 0.80) -> None:
        self._model_path = model_path
        self._threshold = threshold

    def check_liveness(self, image_bytes: bytes) -> LivenessResult:
        raise NotImplementedError
