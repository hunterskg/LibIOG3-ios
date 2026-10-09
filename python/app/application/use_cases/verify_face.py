from app.application.ports.face_detector import FaceDetectorPort
from app.application.ports.face_embedder import FaceEmbedderPort
from app.application.ports.liveness_detector import LivenessDetectorPort
from app.domain.entities.liveness import LivenessStatus
from app.domain.exceptions.face_exceptions import (
    EmbeddingMismatchException,
    FaceNotFoundException,
    MultipleFacesDetectedException,
    SpoofDetectedException,
)
from app.domain.services.similarity import SimilarityCalculator
from app.domain.value_objects.bounding_box import BoundingBox
from app.domain.value_objects.embedding import FaceEmbedding


class VerifyFaceUseCase:
    """Use case xác thực và so khớp 2 khuôn mặt qua pipeline."""

    def __init__(
        self,
        embedder: FaceEmbedderPort,
        similarity_calculator: SimilarityCalculator,
        detector: FaceDetectorPort | None = None,
        liveness_detector: LivenessDetectorPort | None = None,
        validate_quality: bool = True,
        require_single_face: bool = True,
    ) -> None:
        self._embedder = embedder
        self._similarity = similarity_calculator
        self._detector = detector
        self._liveness_detector = liveness_detector
        self._validate_quality = validate_quality
        self._require_single_face = require_single_face

    def execute(
        self,
        image_bytes: bytes,
        reference_embedding: FaceEmbedding,
        bbox: BoundingBox | None = None,
        threshold: float = 0.68,
    ) -> tuple[bool, float]:
        """Thực thi kiểm tra so khớp khuôn mặt với embedding mẫu.

        Returns:
            Tuple (is_matched, similarity_score)
        """
        if not image_bytes:
            raise ValueError("image_bytes is required and cannot be empty")

        target_bbox = bbox
        target_landmarks = None
        if self._detector is not None and target_bbox is None:
            faces = self._detector.detect(image_bytes)
            if len(faces) == 0:
                raise FaceNotFoundException("No face detected for verification")
            if self._require_single_face and len(faces) > 1:
                raise MultipleFacesDetectedException(
                    f"Expected single face for verification, detected {len(faces)}"
                )
            target_face = faces[0]
            target_bbox = target_face.bbox
            target_landmarks = target_face.landmarks
            if self._validate_quality:
                target_face.validate_quality()

        if self._liveness_detector is not None:
            liveness_res = self._liveness_detector.check_liveness(image_bytes)
            if not liveness_res.is_live or liveness_res.status == LivenessStatus.SPOOF:
                raise SpoofDetectedException(
                    f"Spoof detected during verification with confidence {liveness_res.confidence:.2f}"
                )

        if target_landmarks is not None:
            candidate_emb = self._embedder.extract_embedding(
                image_bytes, bbox=target_bbox, landmarks=target_landmarks
            )
        else:
            candidate_emb = self._embedder.extract_embedding(image_bytes, bbox=target_bbox)

        # Đảm bảo cả hai embedding đều được L2-normalized
        candidate_norm = candidate_emb.l2_normalize()
        reference_norm = reference_embedding.l2_normalize()

        if candidate_norm.dimension != reference_norm.dimension:
            raise EmbeddingMismatchException(
                f"Embedding dimension mismatch: candidate {candidate_norm.dimension} "
                f"vs reference {reference_norm.dimension}"
            )

        similarity = self._similarity.compute_cosine_similarity(candidate_norm, reference_norm)
        is_matched = bool(similarity >= threshold)
        return is_matched, float(similarity)
