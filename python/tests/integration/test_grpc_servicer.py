"""Integration tests cho FaceServiceServicer."""

from unittest.mock import MagicMock

from app.interfaces.grpc.servicer import FaceServiceServicer


def test_grpc_servicer_methods_exist():
    """Kiểm tra FaceServiceServicer có đầy đủ RPC method signatures."""
    servicer = FaceServiceServicer(
        detect_face_uc=MagicMock(),
        extract_embedding_uc=MagicMock(),
        verify_face_uc=MagicMock(),
        check_liveness_uc=MagicMock(),
    )

    assert hasattr(servicer, "DetectFaces")
    assert hasattr(servicer, "ExtractEmbedding")
    assert hasattr(servicer, "VerifyFace")
    assert hasattr(servicer, "CheckLiveness")
