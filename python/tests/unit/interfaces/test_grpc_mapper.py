import pytest

from app.domain.entities.face import Face
from app.domain.entities.liveness import LivenessStatus as DomainLivenessStatus
from app.domain.exceptions.face_exceptions import EmbeddingMismatchException
from app.domain.value_objects.bounding_box import BoundingBox
from app.domain.value_objects.landmark import FaceLandmarks, Point2D
from app.interfaces.grpc.mapper import FaceGrpcMapper
from proto.face.v1 import face_pb2


def test_bounding_box_mapping_roundtrip():
    proto_box = face_pb2.BoundingBox(x=10.5, y=20.5, width=100.0, height=120.0, confidence=0.98)
    domain_box = FaceGrpcMapper.to_domain_bounding_box(proto_box)

    assert domain_box is not None
    assert domain_box.x == 10.5
    assert domain_box.y == 20.5
    assert domain_box.width == 100.0
    assert domain_box.height == 120.0
    assert domain_box.confidence == pytest.approx(0.98, rel=1e-3)

    mapped_proto = FaceGrpcMapper.to_proto_bounding_box(domain_box)
    assert mapped_proto is not None
    assert mapped_proto.x == 10.5
    assert mapped_proto.y == 20.5
    assert mapped_proto.width == 100.0
    assert mapped_proto.height == 120.0
    assert mapped_proto.confidence == pytest.approx(0.98, rel=1e-3)


def test_bounding_box_mapping_none():
    assert FaceGrpcMapper.to_domain_bounding_box(None) is None
    assert FaceGrpcMapper.to_proto_bounding_box(None) is None


def test_landmarks_mapping():
    proto_landmarks = [
        face_pb2.Landmark(x=1.0, y=2.0, index=0),
        face_pb2.Landmark(x=3.0, y=4.0, index=1),
    ]
    domain_lm = FaceGrpcMapper.to_domain_landmarks(proto_landmarks)

    assert domain_lm is not None
    assert domain_lm.count() == 2
    assert domain_lm.points[0].x == 1.0
    assert domain_lm.points[0].y == 2.0
    assert domain_lm.points[0].index == 0

    proto_list = FaceGrpcMapper.to_proto_landmarks(domain_lm)
    assert len(proto_list) == 2
    assert proto_list[0].x == 1.0
    assert proto_list[1].y == 4.0

    # Test None / empty
    assert FaceGrpcMapper.to_domain_landmarks(None) is None
    assert FaceGrpcMapper.to_domain_landmarks([]) is None
    assert FaceGrpcMapper.to_proto_landmarks(None) == []


def test_face_detection_mapping():
    box = BoundingBox(x=5.0, y=10.0, width=50.0, height=60.0, confidence=0.95)
    landmarks = FaceLandmarks(points=(Point2D(x=1.0, y=2.0, index=0),))
    face = Face(id="face-123", bbox=box, landmarks=landmarks, confidence=0.95)

    proto_detection = FaceGrpcMapper.to_proto_face_detection(face)
    assert proto_detection.box.x == 5.0
    assert len(proto_detection.landmarks) == 1
    assert proto_detection.confidence == pytest.approx(0.95, rel=1e-3)

    mapped_face = FaceGrpcMapper.to_domain_face(proto_detection, face_id="face-123")
    assert mapped_face.id == "face-123"
    assert mapped_face.bbox.x == 5.0
    assert mapped_face.landmarks is not None
    assert mapped_face.landmarks.count() == 1


def test_face_embedding_mapping():
    values = [0.1] * 512
    proto_emb = face_pb2.FaceEmbedding(values=values, dimension=512)

    domain_emb = FaceGrpcMapper.to_domain_face_embedding(proto_emb)
    assert domain_emb.dimension == 512
    assert len(domain_emb.values) == 512

    mapped_proto = FaceGrpcMapper.to_proto_face_embedding(domain_emb)
    assert mapped_proto.dimension == 512
    assert list(mapped_proto.values) == pytest.approx(values)


def test_face_embedding_mismatch_raises_exception():
    proto_emb = face_pb2.FaceEmbedding(values=[0.1, 0.2], dimension=512)
    with pytest.raises(EmbeddingMismatchException):
        FaceGrpcMapper.to_domain_face_embedding(proto_emb)


def test_liveness_status_mapping():
    # Domain to proto
    assert (
        FaceGrpcMapper.to_proto_liveness_status(DomainLivenessStatus.REAL)
        == face_pb2.LivenessStatus.LIVENESS_REAL
    )
    assert (
        FaceGrpcMapper.to_proto_liveness_status(DomainLivenessStatus.SPOOF)
        == face_pb2.LivenessStatus.LIVENESS_SPOOF
    )
    assert (
        FaceGrpcMapper.to_proto_liveness_status(DomainLivenessStatus.UNKNOWN)
        == face_pb2.LivenessStatus.LIVENESS_UNKNOWN
    )

    # Proto to domain
    assert (
        FaceGrpcMapper.to_domain_liveness_status(face_pb2.LivenessStatus.LIVENESS_REAL)
        == DomainLivenessStatus.REAL
    )
    assert (
        FaceGrpcMapper.to_domain_liveness_status(face_pb2.LivenessStatus.LIVENESS_SPOOF)
        == DomainLivenessStatus.SPOOF
    )
    assert (
        FaceGrpcMapper.to_domain_liveness_status(face_pb2.LivenessStatus.LIVENESS_UNKNOWN)
        == DomainLivenessStatus.UNKNOWN
    )
