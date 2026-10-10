import grpc
import numpy as np

from app.interfaces.grpc.mapper import FaceGrpcMapper
from app.ports.face_detector import (
    FaceDetectorPort,
    FaceNotFoundException,
    MultipleFacesDetectedException,
)
from app.ports.face_embedder import (
    EmbeddingMismatchException,
    FaceEmbedderPort,
)
from app.ports.liveness_detector import (
    LivenessDetectorPort,
    LivenessStatus,
    SpoofDetectedException,
)
from proto.face.v1 import face_pb2, face_pb2_grpc


class FaceServiceServicer(face_pb2_grpc.FaceServiceServicer):
    """Triển khai 4 RPC method cho FaceService qua Ports."""

    def __init__(
        self,
        detector: FaceDetectorPort,
        embedder: FaceEmbedderPort,
        liveness_detector: LivenessDetectorPort | None = None,
        validate_quality: bool = True,
        require_single_face: bool = True,
    ) -> None:
        self._detector = detector
        self._embedder = embedder
        self._liveness_detector = liveness_detector
        self._validate_quality = validate_quality
        self._require_single_face = require_single_face

    def DetectFaces(
        self,
        request: face_pb2.DetectFacesRequest,
        context: grpc.ServicerContext,
    ) -> face_pb2.DetectFacesResponse:
        """RPC DetectFaces handler."""
        if not request.image_bytes:
            raise ValueError("image_bytes is required")

        max_faces = request.max_faces if request.max_faces > 0 else 1
        faces = self._detector.detect(request.image_bytes)
        if max_faces > 0:
            faces = faces[:max_faces]

        detections = [FaceGrpcMapper.to_proto_face_detection(f) for f in faces]
        return face_pb2.DetectFacesResponse(
            detections=detections,
            success=True,
            error="",
        )

    def ExtractEmbedding(
        self,
        request: face_pb2.ExtractEmbeddingRequest,
        context: grpc.ServicerContext,
    ) -> face_pb2.ExtractEmbeddingResponse:
        """RPC ExtractEmbedding handler."""
        if not request.image_bytes:
            raise ValueError("image_bytes is required")

        bbox = None
        if (hasattr(request, "HasField") and request.HasField("bbox")) or getattr(
            request, "bbox", None
        ) is not None:
            bbox = FaceGrpcMapper.to_domain_bounding_box(request.bbox)

        embedding = self._embedder.extract_embedding(
            image_bytes=request.image_bytes,
            bbox=bbox,
        )
        proto_emb = FaceGrpcMapper.to_proto_face_embedding(embedding)
        return face_pb2.ExtractEmbeddingResponse(
            embedding=proto_emb,
            success=True,
            error="",
        )

    def VerifyFace(
        self,
        request: face_pb2.VerifyFaceRequest,
        context: grpc.ServicerContext,
    ) -> face_pb2.VerifyFaceResponse:
        """RPC VerifyFace handler."""
        if not request.image_bytes:
            raise ValueError("image_bytes is required")

        has_ref = False
        if hasattr(request, "HasField"):
            has_ref = request.HasField("reference_embedding")
        else:
            has_ref = getattr(request, "reference_embedding", None) is not None

        if not has_ref:
            raise ValueError("reference_embedding is required")

        ref_emb = FaceGrpcMapper.to_domain_face_embedding(request.reference_embedding)

        bbox = None
        if (hasattr(request, "HasField") and request.HasField("bbox")) or getattr(
            request, "bbox", None
        ) is not None:
            bbox = FaceGrpcMapper.to_domain_bounding_box(request.bbox)

        target_bbox = bbox
        target_landmarks = None
        if self._detector is not None and target_bbox is None:
            faces = self._detector.detect(request.image_bytes)
            if len(faces) == 0:
                raise FaceNotFoundException("No face detected for verification")
            if self._require_single_face and len(faces) > 1:
                raise MultipleFacesDetectedException(
                    f"Expected single face for verification, detected {len(faces)}"
                )
            target_face = faces[0]
            target_bbox = target_face.bbox
            target_landmarks = target_face.landmarks
            if self._validate_quality and hasattr(target_face, "validate_quality"):
                target_face.validate_quality()

        if self._liveness_detector is not None:
            liveness_res = self._liveness_detector.check_liveness(request.image_bytes)
            if not liveness_res.is_live or liveness_res.status == LivenessStatus.SPOOF:
                raise SpoofDetectedException(
                    f"Spoof detected during verification with confidence {liveness_res.confidence:.2f}"
                )

        if target_landmarks is not None:
            candidate_emb = self._embedder.extract_embedding(
                request.image_bytes, bbox=target_bbox, landmarks=target_landmarks
            )
        else:
            candidate_emb = self._embedder.extract_embedding(
                request.image_bytes, bbox=target_bbox
            )

        candidate_norm = candidate_emb.l2_normalize()
        reference_norm = ref_emb.l2_normalize()

        if candidate_norm.dimension != reference_norm.dimension:
            raise EmbeddingMismatchException(
                f"Embedding dimension mismatch: candidate {candidate_norm.dimension} "
                f"vs reference {reference_norm.dimension}"
            )

        similarity = candidate_norm.cosine_similarity(reference_norm)

        threshold = request.threshold if request.threshold > 0.0 else 0.68
        matched = bool(similarity >= threshold)

        return face_pb2.VerifyFaceResponse(
            matched=matched,
            similarity=float(similarity),
            success=True,
            error="",
        )

    def CheckLiveness(
        self,
        request: face_pb2.CheckLivenessRequest,
        context: grpc.ServicerContext,
    ) -> face_pb2.CheckLivenessResponse:
        """RPC CheckLiveness handler."""
        if not request.image_bytes:
            raise ValueError("image_bytes is required")

        if self._liveness_detector is None:
            raise ValueError("Liveness detector is not configured")

        liveness_res = self._liveness_detector.check_liveness(image_bytes=request.image_bytes)
        proto_status = FaceGrpcMapper.to_proto_liveness_status(liveness_res.status)
        return face_pb2.CheckLivenessResponse(
            status=proto_status,
            confidence=float(liveness_res.confidence),
            success=True,
            error="",
        )
