"""Unit tests cho HTTP API test nhận diện khuôn mặt."""

import json
from unittest.mock import MagicMock

from app.domain.entities.face import Face
from app.domain.value_objects.bounding_box import BoundingBox
from app.domain.value_objects.embedding import FaceEmbedding
from test_api import FaceComparatorService


def test_face_comparator_service_validation():
    """Kiểm tra validation dữ liệu đầu vào của FaceComparatorService."""
    service = FaceComparatorService()
    assert service.compare(b"", b"img2")["matched"] is False
    assert "error" in service.compare(b"", b"img2")
    assert service.compare(b"img1", b"")["matched"] is False
    assert "error" in service.compare(b"img1", b"")


def test_face_comparator_service_success():
    """Kiểm tra compare trả về matched và similarity chính xác."""
    service = FaceComparatorService()
    service.detector = MagicMock()
    service.embedder = MagicMock()
    service.similarity_calculator = MagicMock()

    face1 = Face(
        id="f1",
        bbox=BoundingBox(x=10.0, y=10.0, width=50.0, height=50.0),
        confidence=0.99,
    )
    face2 = Face(
        id="f2",
        bbox=BoundingBox(x=15.0, y=15.0, width=52.0, height=52.0),
        confidence=0.98,
    )

    service.detector.detect.side_effect = [[face1], [face2]]
    emb1 = FaceEmbedding(values=tuple([0.5] * 512), dimension=512)
    emb2 = FaceEmbedding(values=tuple([0.5] * 512), dimension=512)
    service.embedder.extract_embedding.side_effect = [emb1, emb2]
    service.similarity_calculator.compute_cosine_similarity.return_value = 0.92

    res = service.compare(b"img1", b"img2", threshold=0.65)

    assert res["matched"] is True
    assert res["similarity"] == 0.92
    assert res["threshold"] == 0.65
    assert res["faces_found"]["image1"] == 1
    assert res["faces_found"]["image2"] == 1


def test_face_comparator_service_no_face_found():
    """Kiểm tra trường hợp ảnh không phát hiện khuôn mặt."""
    service = FaceComparatorService()
    service.detector = MagicMock()
    service.detector.detect.return_value = []

    res = service.compare(b"no_face_img", b"img2")
    assert res["matched"] is False
    assert "Không tìm thấy khuôn mặt trong ảnh 1" in res["error"]


def test_http_handler_endpoints():
    """Kiểm tra các route GET / và GET /health của HTTP Handler."""
    import threading
    import urllib.request
    from http.server import ThreadingHTTPServer

    from test_api import create_handler

    service = FaceComparatorService()
    handler_class = create_handler(service)
    server = ThreadingHTTPServer(("127.0.0.1", 0), handler_class)
    port = server.server_port

    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()

    try:
        # GET /
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/") as resp:
            assert resp.status == 200
            content = resp.read().decode("utf-8")
            assert "Face Comparison" in content

        # GET /health
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/health") as resp:
            assert resp.status == 200
            data = json.loads(resp.read().decode("utf-8"))
            assert data["status"] == "ok"
    finally:
        server.shutdown()
        server.server_close()
