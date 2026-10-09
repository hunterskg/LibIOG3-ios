import uuid
from collections.abc import Iterable

from app.domain.entities.face import Face
from app.domain.entities.liveness import LivenessStatus as DomainLivenessStatus
from app.domain.exceptions.face_exceptions import EmbeddingMismatchException
from app.domain.value_objects.bounding_box import BoundingBox
from app.domain.value_objects.embedding import FaceEmbedding
from app.domain.value_objects.landmark import FaceLandmarks, Point2D
from proto.face.v1 import face_pb2


class FaceGrpcMapper:
    """Mapper hai chiều giữa Protobuf messages và Domain models."""

    @staticmethod
    def to_domain_bounding_box(proto_box: face_pb2.BoundingBox | None) -> BoundingBox | None:
        """Chuyển đổi protobuf BoundingBox sang domain BoundingBox."""
        if proto_box is None:
            return None
        return BoundingBox(
            x=float(proto_box.x),
            y=float(proto_box.y),
            width=float(proto_box.width),
            height=float(proto_box.height),
            confidence=float(proto_box.confidence),
        )

    @staticmethod
    def to_proto_bounding_box(box: BoundingBox | None) -> face_pb2.BoundingBox | None:
        """Chuyển đổi domain BoundingBox sang protobuf BoundingBox."""
        if box is None:
            return None
        return face_pb2.BoundingBox(
            x=box.x,
            y=box.y,
            width=box.width,
            height=box.height,
            confidence=box.confidence,
        )

    @staticmethod
    def to_domain_landmarks(
        proto_landmarks: Iterable[face_pb2.Landmark] | None,
    ) -> FaceLandmarks | None:
        """Chuyển đổi danh sách protobuf Landmark sang domain FaceLandmarks."""
        if proto_landmarks is None:
            return None
        points = tuple(
            Point2D(x=float(lm.x), y=float(lm.y), index=int(lm.index)) for lm in proto_landmarks
        )
        if not points:
            return None
        return FaceLandmarks(points=points)

    @staticmethod
    def to_proto_landmarks(landmarks: FaceLandmarks | None) -> list[face_pb2.Landmark]:
        """Chuyển đổi domain FaceLandmarks sang danh sách protobuf Landmark."""
        if landmarks is None:
            return []
        return [face_pb2.Landmark(x=p.x, y=p.y, index=p.index) for p in landmarks.points]

    @staticmethod
    def to_proto_face_detection(face: Face) -> face_pb2.FaceDetection:
        """Chuyển đổi domain Face sang protobuf FaceDetection."""
        return face_pb2.FaceDetection(
            box=FaceGrpcMapper.to_proto_bounding_box(face.bbox),
            landmarks=FaceGrpcMapper.to_proto_landmarks(face.landmarks),
            confidence=face.confidence,
        )

    @staticmethod
    def to_domain_face(
        proto_detection: face_pb2.FaceDetection,
        face_id: str | None = None,
    ) -> Face:
        """Chuyển đổi protobuf FaceDetection sang domain Face."""
        bbox = FaceGrpcMapper.to_domain_bounding_box(proto_detection.box)
        if bbox is None:
            bbox = BoundingBox(x=0.0, y=0.0, width=0.0, height=0.0, confidence=0.0)
        landmarks = FaceGrpcMapper.to_domain_landmarks(proto_detection.landmarks)
        return Face(
            id=face_id or str(uuid.uuid4()),
            bbox=bbox,
            landmarks=landmarks,
            confidence=float(proto_detection.confidence),
        )

    @staticmethod
    def to_domain_face_embedding(proto_emb: face_pb2.FaceEmbedding) -> FaceEmbedding:
        """Chuyển đổi protobuf FaceEmbedding sang domain FaceEmbedding."""
        if len(proto_emb.values) != proto_emb.dimension:
            raise EmbeddingMismatchException(
                f"Embedding values count {len(proto_emb.values)} "
                f"does not match dimension {proto_emb.dimension}"
            )
        return FaceEmbedding(
            values=tuple(float(v) for v in proto_emb.values),
            dimension=int(proto_emb.dimension),
        )

    @staticmethod
    def to_proto_face_embedding(emb: FaceEmbedding) -> face_pb2.FaceEmbedding:
        """Chuyển đổi domain FaceEmbedding sang protobuf FaceEmbedding."""
        return face_pb2.FaceEmbedding(
            values=list(emb.values),
            dimension=emb.dimension,
        )

    @staticmethod
    def to_proto_liveness_status(status: DomainLivenessStatus) -> face_pb2.LivenessStatus:
        """Chuyển đổi domain LivenessStatus sang protobuf LivenessStatus enum value."""
        if status == DomainLivenessStatus.REAL:
            return face_pb2.LivenessStatus.LIVENESS_REAL
        if status == DomainLivenessStatus.SPOOF:
            return face_pb2.LivenessStatus.LIVENESS_SPOOF
        return face_pb2.LivenessStatus.LIVENESS_UNKNOWN

    @staticmethod
    def to_domain_liveness_status(
        proto_status: face_pb2.LivenessStatus | int,
    ) -> DomainLivenessStatus:
        """Chuyển đổi protobuf LivenessStatus enum value sang domain LivenessStatus."""
        if proto_status == face_pb2.LivenessStatus.LIVENESS_REAL:
            return DomainLivenessStatus.REAL
        if proto_status == face_pb2.LivenessStatus.LIVENESS_SPOOF:
            return DomainLivenessStatus.SPOOF
        return DomainLivenessStatus.UNKNOWN
