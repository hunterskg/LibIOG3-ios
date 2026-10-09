from __future__ import annotations

from app.application.ports.face_detector import FaceDetectorPort
from app.application.ports.face_embedder import FaceEmbedderPort
from app.application.ports.liveness_detector import LivenessDetectorPort
from app.domain.entities.liveness import LivenessStatus
from app.domain.exceptions.face_exceptions import (
    FaceNotFoundException,
    MultipleFacesDetectedException,
    SpoofDetectedException,
)
from app.domain.value_objects.bounding_box import BoundingBox
from app.domain.value_objects.embedding import FaceEmbedding
from app.domain.value_objects.landmark import FaceLandmarks


class ExtractEmbeddingUseCase:
    """Use case trích xuất embedding từ khuôn mặt theo pipeline."""

    def __init__(
        self,
        embedder: FaceEmbedderPort,
        detector: FaceDetectorPort | None = None,
        liveness_detector: LivenessDetectorPort | None = None,
        validate_quality: bool = True,
        require_single_face: bool = True,
    ) -> None:
        self._embedder = embedder
        self._detector = detector
        self._liveness_detector = liveness_detector
        self._validate_quality = validate_quality
        self._require_single_face = require_single_face

    def execute(
        self,
        image_bytes: bytes,
        bbox: BoundingBox | None = None,
        landmarks: FaceLandmarks | None = None,
    ) -> FaceEmbedding:
        """Thực thi trích xuất embedding qua pipeline Detector -> Liveness -> Embedder -> L2-Normalization."""
        if not image_bytes:
            raise ValueError("image_bytes is required and cannot be empty")

        target_bbox = bbox
        target_landmarks = landmarks
        if self._detector is not None and target_bbox is None:
            faces = self._detector.detect(image_bytes)
            if len(faces) == 0:
                raise FaceNotFoundException("No face detected in image")
            if self._require_single_face and len(faces) > 1:
                raise MultipleFacesDetectedException(f"Expected single face, detected {len(faces)}")
            target_face = faces[0]
            target_bbox = target_face.bbox
            if target_landmarks is None:
                target_landmarks = target_face.landmarks
            if self._validate_quality:
                target_face.validate_quality()

        if self._liveness_detector is not None:
            liveness_res = self._liveness_detector.check_liveness(image_bytes)
            if not liveness_res.is_live or liveness_res.status == LivenessStatus.SPOOF:
                raise SpoofDetectedException(
                    f"Spoof detected with confidence {liveness_res.confidence:.2f}"
                )

        if target_landmarks is not None:
            embedding = self._embedder.extract_embedding(
                image_bytes, bbox=target_bbox, landmarks=target_landmarks
            )
        else:
            embedding = self._embedder.extract_embedding(image_bytes, bbox=target_bbox)

        return embedding.l2_normalize()
