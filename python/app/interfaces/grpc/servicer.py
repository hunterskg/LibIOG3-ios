import grpc

from app.application.use_cases.check_liveness import CheckLivenessUseCase
from app.application.use_cases.detect_face import DetectFaceUseCase
from app.application.use_cases.extract_embedding import ExtractEmbeddingUseCase
from app.application.use_cases.verify_face import VerifyFaceUseCase
from app.interfaces.grpc.mapper import FaceGrpcMapper
from proto.face.v1 import face_pb2, face_pb2_grpc


class FaceServiceServicer(face_pb2_grpc.FaceServiceServicer):
    """Triển khai 4 RPC method cho FaceService."""

    def __init__(
        self,
        detect_face_uc: DetectFaceUseCase,
        extract_embedding_uc: ExtractEmbeddingUseCase,
        verify_face_uc: VerifyFaceUseCase,
        check_liveness_uc: CheckLivenessUseCase,
    ) -> None:
        self._detect_face_uc = detect_face_uc
        self._extract_embedding_uc = extract_embedding_uc
        self._verify_face_uc = verify_face_uc
        self._check_liveness_uc = check_liveness_uc

    def DetectFaces(
        self,
        request: face_pb2.DetectFacesRequest,
        context: grpc.ServicerContext,
    ) -> face_pb2.DetectFacesResponse:
        """RPC DetectFaces handler."""
        if not request.image_bytes:
            raise ValueError("image_bytes is required")

        max_faces = request.max_faces if request.max_faces > 0 else 1
        faces = self._detect_face_uc.execute(
            image_bytes=request.image_bytes,
            max_faces=max_faces,
        )
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

        embedding = self._extract_embedding_uc.execute(
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

        threshold = request.threshold if request.threshold > 0.0 else 0.68
        matched, similarity = self._verify_face_uc.execute(
            image_bytes=request.image_bytes,
            reference_embedding=ref_emb,
            bbox=bbox,
            threshold=threshold,
        )
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

        liveness_res = self._check_liveness_uc.execute(image_bytes=request.image_bytes)
        proto_status = FaceGrpcMapper.to_proto_liveness_status(liveness_res.status)
        return face_pb2.CheckLivenessResponse(
            status=proto_status,
            confidence=float(liveness_res.confidence),
            success=True,
            error="",
        )
