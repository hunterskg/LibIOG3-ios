from app.application.ports.face_detector import FaceDetectorPort
from app.application.ports.liveness_detector import LivenessDetectorPort
from app.domain.entities.liveness import LivenessResult
from app.domain.exceptions.face_exceptions import FaceNotFoundException


class CheckLivenessUseCase:
    """Use case kiểm tra liveness chống giả mạo."""

    def __init__(
        self,
        liveness_detector: LivenessDetectorPort,
        detector: FaceDetectorPort | None = None,
    ) -> None:
        self._liveness_detector = liveness_detector
        self._detector = detector

    def execute(self, image_bytes: bytes) -> LivenessResult:
        """Thực thi kiểm tra liveness."""
        if not image_bytes:
            raise ValueError("image_bytes is required and cannot be empty")

        if self._detector is not None:
            faces = self._detector.detect(image_bytes)
            if len(faces) == 0:
                raise FaceNotFoundException("No face detected for liveness check")

        return self._liveness_detector.check_liveness(image_bytes)
