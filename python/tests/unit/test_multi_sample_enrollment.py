"""Unit tests cho Multi-Sample Enrollment và nhận diện."""

from unittest.mock import MagicMock

import numpy as np
import pytest

from test_api import MultiSampleEnrollmentService


def _make_client_with_embeddings(embeddings: list[list[float]]) -> MagicMock:
    """Tạo mock client trả về embeddings tuần tự."""
    client = MagicMock()
    client.extract_embedding.side_effect = embeddings
    return client


def test_enroll_computes_average_and_l2_normalized_template():
    """Kiểm tra enroll tính trung bình từ 3 vector và chuẩn hóa L2."""
    emb1 = [1.0] + [0.0] * 511
    emb2 = [0.0, 1.0] + [0.0] * 510
    emb3 = [0.0, 0.0, 1.0] + [0.0] * 509

    client = _make_client_with_embeddings([emb1, emb2, emb3])
    service = MultiSampleEnrollmentService(client=client)

    res = service.enroll([b"img1", b"img2", b"img3"])

    assert res["sample_count"] == 3
    assert res["dimension"] == 512
    assert len(res["template_embedding"]) == 512
    assert len(res["sample_embeddings"]) == 3

    # Kiểm tra template đã L2-normalized
    norm = float(np.linalg.norm(np.array(res["template_embedding"])))
    assert pytest.approx(norm, abs=1e-3) == 1.0


def test_enroll_with_five_samples_l2_normalized():
    """Kiểm tra enroll với 5 ảnh mẫu vẫn tạo template chuẩn L2 norm."""
    base = [0.2] * 512
    client = _make_client_with_embeddings([base] * 5)
    service = MultiSampleEnrollmentService(client=client)

    res = service.enroll([b"a", b"b", b"c", b"d", b"e"])

    assert res["sample_count"] == 5
    norm = float(np.linalg.norm(np.array(res["template_embedding"])))
    assert pytest.approx(norm, abs=1e-3) == 1.0


def test_enroll_empty_list_raises_value_error():
    """Kiểm tra enroll ném ValueError khi không có ảnh mẫu."""
    client = MagicMock()
    service = MultiSampleEnrollmentService(client=client)

    with pytest.raises(ValueError, match="cannot be empty"):
        service.enroll([])


def test_verify_matched_when_similarity_above_threshold():
    """Kiểm tra verify trả về matched=True khi similarity >= 0.68."""
    client = MagicMock()
    client.verify_face.return_value = (True, 0.85)
    service = MultiSampleEnrollmentService(client=client)

    template = [0.1] * 512
    res = service.verify(b"probe", template, threshold=0.68)

    assert res["matched"] is True
    assert res["similarity"] == pytest.approx(0.85)
    assert res["threshold"] == pytest.approx(0.68)
    assert "MATCHED" in res["decision"]
    client.verify_face.assert_called_once_with(b"probe", template, threshold=0.68)


def test_verify_not_matched_when_similarity_below_threshold():
    """Kiểm tra verify trả về matched=False khi similarity < 0.68."""
    client = MagicMock()
    client.verify_face.return_value = (False, 0.30)
    service = MultiSampleEnrollmentService(client=client)

    res = service.verify(b"probe", [0.1] * 512, threshold=0.68)

    assert res["matched"] is False
    assert res["similarity"] == pytest.approx(0.30)
    assert "NOT MATCHED" in res["decision"]


def test_verify_empty_probe_raises_value_error():
    """Kiểm tra verify ném ValueError khi probe rỗng."""
    client = MagicMock()
    service = MultiSampleEnrollmentService(client=client)

    with pytest.raises(ValueError, match="probe_image_bytes cannot be empty"):
        service.verify(b"", [0.1] * 512)


def test_verify_empty_template_raises_value_error():
    """Kiểm tra verify ném ValueError khi template rỗng."""
    client = MagicMock()
    service = MultiSampleEnrollmentService(client=client)

    with pytest.raises(ValueError, match="template_embedding cannot be empty"):
        service.verify(b"probe", [])
