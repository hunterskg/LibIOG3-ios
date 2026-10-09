from app.application.ports.face_detector import FaceDetectorPort
from app.domain.entities.face import Face


class DetectFaceUseCase:
    """Use case nhận diện khuôn mặt."""

    def __init__(self, detector: FaceDetectorPort) -> None:
        self._detector = detector

    def execute(self, image_bytes: bytes, max_faces: int = 1) -> list[Face]:
        """Thực thi nhận diện khuôn mặt."""
        if not image_bytes:
            raise ValueError("image_bytes is required and cannot be empty")

        faces = self._detector.detect(image_bytes)
        if max_faces > 0:
            return faces[:max_faces]
        return faces
