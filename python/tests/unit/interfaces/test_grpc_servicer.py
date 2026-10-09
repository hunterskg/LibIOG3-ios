from unittest.mock import MagicMock

import pytest

from app.domain.entities.face import Face
from app.domain.entities.liveness import LivenessResult, LivenessStatus
from app.domain.value_objects.bounding_box import BoundingBox
from app.domain.value_objects.embedding import FaceEmbedding
from app.interfaces.grpc.servicer import FaceServiceServicer
from proto.face.v1 import face_pb2


@pytest.fixture
def mock_use_cases():
    return {
        "detect_face_uc": MagicMock(),
        "extract_embedding_uc": MagicMock(),
        "verify_face_uc": MagicMock(),
        "check_liveness_uc": MagicMock(),
    }


@pytest.fixture
def servicer(mock_use_cases):
    return FaceServiceServicer(
        detect_face_uc=mock_use_cases["detect_face_uc"],
        extract_embedding_uc=mock_use_cases["extract_embedding_uc"],
        verify_face_uc=mock_use_cases["verify_face_uc"],
        check_liveness_uc=mock_use_cases["check_liveness_uc"],
    )


def test_detect_faces_empty_image_raises_value_error(servicer):
    request = face_pb2.DetectFacesRequest(image_bytes=b"", max_faces=1)
    context = MagicMock()

    with pytest.raises(ValueError, match="image_bytes is required"):
        servicer.DetectFaces(request, context)


def test_detect_faces_success(servicer, mock_use_cases):
    bbox = BoundingBox(x=10.0, y=20.0, width=50.0, height=60.0, confidence=0.95)
    face = Face(id="face-1", bbox=bbox, landmarks=None, confidence=0.95)
    mock_use_cases["detect_face_uc"].execute.return_value = [face]

    request = face_pb2.DetectFacesRequest(image_bytes=b"test_image_bytes", max_faces=2)
    context = MagicMock()

    response = servicer.DetectFaces(request, context)

    assert response.success is True
    assert len(response.detections) == 1
    assert response.detections[0].box.x == 10.0
    assert response.detections[0].box.width == 50.0
    mock_use_cases["detect_face_uc"].execute.assert_called_once_with(
        image_bytes=b"test_image_bytes",
        max_faces=2,
    )


def test_detect_faces_default_max_faces(servicer, mock_use_cases):
    mock_use_cases["detect_face_uc"].execute.return_value = []

    request = face_pb2.DetectFacesRequest(image_bytes=b"test_image_bytes", max_faces=0)
    context = MagicMock()

    response = servicer.DetectFaces(request, context)

    assert response.success is True
    assert len(response.detections) == 0
    mock_use_cases["detect_face_uc"].execute.assert_called_once_with(
        image_bytes=b"test_image_bytes",
        max_faces=1,
    )


def test_extract_embedding_empty_image_raises_value_error(servicer):
    request = face_pb2.ExtractEmbeddingRequest(image_bytes=b"")
    context = MagicMock()

    with pytest.raises(ValueError, match="image_bytes is required"):
        servicer.ExtractEmbedding(request, context)


def test_extract_embedding_success(servicer, mock_use_cases):
    embedding_values = tuple([0.5] * 512)
    mock_use_cases["extract_embedding_uc"].execute.return_value = FaceEmbedding(
        values=embedding_values,
        dimension=512,
    )

    proto_box = face_pb2.BoundingBox(x=5.0, y=5.0, width=40.0, height=40.0, confidence=0.9)
    request = face_pb2.ExtractEmbeddingRequest(
        image_bytes=b"test_image_bytes",
        bbox=proto_box,
    )
    context = MagicMock()

    response = servicer.ExtractEmbedding(request, context)

    assert response.success is True
    assert response.embedding.dimension == 512
    assert len(response.embedding.values) == 512
    assert response.embedding.values[0] == pytest.approx(0.5)

    mock_use_cases["extract_embedding_uc"].execute.assert_called_once()
    called_kwargs = mock_use_cases["extract_embedding_uc"].execute.call_args.kwargs
    assert called_kwargs["image_bytes"] == b"test_image_bytes"
    assert called_kwargs["bbox"] is not None
    assert called_kwargs["bbox"].x == 5.0


def test_verify_face_empty_image_raises_value_error(servicer):
    proto_emb = face_pb2.FaceEmbedding(values=[0.1] * 512, dimension=512)
    request = face_pb2.VerifyFaceRequest(image_bytes=b"", reference_embedding=proto_emb)
    context = MagicMock()

    with pytest.raises(ValueError, match="image_bytes is required"):
        servicer.VerifyFace(request, context)


def test_verify_face_missing_reference_embedding_raises_value_error(servicer):
    request = face_pb2.VerifyFaceRequest(image_bytes=b"test_image")
    context = MagicMock()

    with pytest.raises(ValueError, match="reference_embedding is required"):
        servicer.VerifyFace(request, context)


def test_verify_face_success(servicer, mock_use_cases):
    mock_use_cases["verify_face_uc"].execute.return_value = (True, 0.92)

    proto_emb = face_pb2.FaceEmbedding(values=[0.1] * 512, dimension=512)
    request = face_pb2.VerifyFaceRequest(
        image_bytes=b"test_image_bytes",
        reference_embedding=proto_emb,
        threshold=0.75,
    )
    context = MagicMock()

    response = servicer.VerifyFace(request, context)

    assert response.success is True
    assert response.matched is True
    assert response.similarity == pytest.approx(0.92, rel=1e-3)

    mock_use_cases["verify_face_uc"].execute.assert_called_once()
    called_kwargs = mock_use_cases["verify_face_uc"].execute.call_args.kwargs
    assert called_kwargs["image_bytes"] == b"test_image_bytes"
    assert called_kwargs["reference_embedding"].dimension == 512
    assert called_kwargs["threshold"] == pytest.approx(0.75)


def test_verify_face_default_threshold(servicer, mock_use_cases):
    mock_use_cases["verify_face_uc"].execute.return_value = (False, 0.40)

    proto_emb = face_pb2.FaceEmbedding(values=[0.1] * 512, dimension=512)
    request = face_pb2.VerifyFaceRequest(
        image_bytes=b"test_image_bytes",
        reference_embedding=proto_emb,
        threshold=0.0,
    )
    context = MagicMock()

    response = servicer.VerifyFace(request, context)

    assert response.success is True
    assert response.matched is False
    assert response.similarity == pytest.approx(0.40, rel=1e-3)

    called_kwargs = mock_use_cases["verify_face_uc"].execute.call_args.kwargs
    assert called_kwargs["threshold"] == pytest.approx(0.68)


def test_check_liveness_empty_image_raises_value_error(servicer):
    request = face_pb2.CheckLivenessRequest(image_bytes=b"")
    context = MagicMock()

    with pytest.raises(ValueError, match="image_bytes is required"):
        servicer.CheckLiveness(request, context)


def test_check_liveness_success(servicer, mock_use_cases):
    mock_use_cases["check_liveness_uc"].execute.return_value = LivenessResult(
        is_live=True,
        status=LivenessStatus.REAL,
        confidence=0.98,
    )

    request = face_pb2.CheckLivenessRequest(image_bytes=b"test_image_bytes")
    context = MagicMock()

    response = servicer.CheckLiveness(request, context)

    assert response.success is True
    assert response.status == face_pb2.LivenessStatus.LIVENESS_REAL
    assert response.confidence == pytest.approx(0.98, rel=1e-3)

    mock_use_cases["check_liveness_uc"].execute.assert_called_once_with(
        image_bytes=b"test_image_bytes"
    )
