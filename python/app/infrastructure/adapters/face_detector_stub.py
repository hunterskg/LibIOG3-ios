from app.application.ports.face_detector import FaceDetectorPort
from app.domain.entities.face import Face


class StubFaceDetector(FaceDetectorPort):
    """Adapter stub cho FaceDetectorPort (không logic chi tiết)."""

    def __init__(self, model_path: str = "models/detector.onnx") -> None:
        self._model_path = model_path

    def detect(self, image_bytes: bytes) -> list[Face]:
        raise NotImplementedError
