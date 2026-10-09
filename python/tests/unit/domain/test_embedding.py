"""Unit tests cho FaceEmbedding.l2_normalize() và is_l2_normalized()."""

import numpy as np

from app.domain.value_objects.embedding import FaceEmbedding


def test_l2_normalize_returns_unit_vector():
    embedding = FaceEmbedding(values=tuple([1.0, 2.0, 3.0] + [0.0] * 509), dimension=512)
    normalized = embedding.l2_normalize()
    assert normalized.dimension == 512
    assert normalized.is_l2_normalized(tolerance=1e-3) is True
    norm = float(np.linalg.norm(normalized.values))
    assert abs(norm - 1.0) < 1e-3


def test_l2_normalize_does_not_mutate_original():
    embedding = FaceEmbedding(values=tuple([3.0] * 512), dimension=512)
    _ = embedding.l2_normalize()
    # Giá trị gốc không đổi
    assert all(v == 3.0 for v in embedding.values)


def test_l2_normalize_zero_vector_does_not_fail():
    embedding = FaceEmbedding(values=tuple([0.0] * 512), dimension=512)
    normalized = embedding.l2_normalize()
    assert normalized.dimension == 512
    assert len(normalized.values) == 512


def test_is_l2_normalized_true_for_unit_vector():
    embedding = FaceEmbedding(values=tuple([1.0] + [0.0] * 511), dimension=512)
    assert embedding.is_l2_normalized() is True


def test_is_l2_normalized_false_for_non_unit_vector():
    embedding = FaceEmbedding(values=tuple([3.0] * 512), dimension=512)
    assert embedding.is_l2_normalized() is False
