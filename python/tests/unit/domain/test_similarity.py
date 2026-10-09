"""Unit tests cho SimilarityCalculator Protocol và Numpy implementation."""

import pytest

from app.domain.exceptions.face_exceptions import EmbeddingMismatchException
from app.domain.services.similarity import SimilarityCalculator
from app.domain.value_objects.embedding import FaceEmbedding
from app.infrastructure.adapters.numpy_similarity_calculator import NumpySimilarityCalculator


def test_similarity_protocol_methods():
    """Kiểm tra Protocol có đủ methods định nghĩa."""
    assert hasattr(SimilarityCalculator, "compute_cosine_similarity")
    assert hasattr(SimilarityCalculator, "compute_euclidean_distance")


def test_similarity_protocol_implementation():
    """Kiểm tra một class thực thi đầy đủ protocol."""

    class DummySimilarityCalculator:
        def compute_cosine_similarity(self, emb1: FaceEmbedding, emb2: FaceEmbedding) -> float:
            return 1.0

        def compute_euclidean_distance(self, emb1: FaceEmbedding, emb2: FaceEmbedding) -> float:
            return 0.0

    calc = DummySimilarityCalculator()
    emb1 = FaceEmbedding(values=(1.0, 2.0), dimension=2)
    emb2 = FaceEmbedding(values=(1.0, 2.0), dimension=2)
    assert calc.compute_cosine_similarity(emb1, emb2) == 1.0
    assert calc.compute_euclidean_distance(emb1, emb2) == 0.0


def test_numpy_similarity_calculator_protocol_conformance():
    """Kiểm tra NumpySimilarityCalculator tuân thủ SimilarityCalculator protocol."""
    calc = NumpySimilarityCalculator()
    assert isinstance(calc, SimilarityCalculator)


def test_compute_cosine_similarity_values():
    """Kiểm tra tính cosine similarity các trường hợp chuẩn."""
    calc = NumpySimilarityCalculator()

    # Cùng hướng -> 1.0
    emb1 = FaceEmbedding(values=(1.0, 2.0, 3.0), dimension=3)
    emb2 = FaceEmbedding(values=(2.0, 4.0, 6.0), dimension=3)
    assert pytest.approx(calc.compute_cosine_similarity(emb1, emb2), rel=1e-5) == 1.0

    # Vuông góc -> 0.0
    emb_orth1 = FaceEmbedding(values=(1.0, 0.0), dimension=2)
    emb_orth2 = FaceEmbedding(values=(0.0, 1.0), dimension=2)
    assert pytest.approx(calc.compute_cosine_similarity(emb_orth1, emb_orth2), abs=1e-6) == 0.0

    # Ngược hướng -> -1.0
    emb_neg = FaceEmbedding(values=(-1.0, -2.0, -3.0), dimension=3)
    assert pytest.approx(calc.compute_cosine_similarity(emb1, emb_neg), rel=1e-5) == -1.0


def test_compute_cosine_similarity_zero_vector():
    """Kiểm tra vector 0 không gây chia cho 0."""
    calc = NumpySimilarityCalculator()
    zero_emb = FaceEmbedding(values=(0.0, 0.0), dimension=2)
    other_emb = FaceEmbedding(values=(1.0, 2.0), dimension=2)
    assert calc.compute_cosine_similarity(zero_emb, other_emb) == 0.0


def test_similarity_dimension_mismatch():
    """Kiểm tra lệch số chiều ném EmbeddingMismatchException."""
    calc = NumpySimilarityCalculator()
    emb2d = FaceEmbedding(values=(1.0, 2.0), dimension=2)
    emb3d = FaceEmbedding(values=(1.0, 2.0, 3.0), dimension=3)

    with pytest.raises(EmbeddingMismatchException):
        calc.compute_cosine_similarity(emb2d, emb3d)

    with pytest.raises(EmbeddingMismatchException):
        calc.compute_euclidean_distance(emb2d, emb3d)


def test_compute_euclidean_distance():
    """Kiểm tra tính khoảng cách Euclidean chuẩn."""
    calc = NumpySimilarityCalculator()
    emb1 = FaceEmbedding(values=(0.0, 0.0), dimension=2)
    emb2 = FaceEmbedding(values=(3.0, 4.0), dimension=2)
    assert pytest.approx(calc.compute_euclidean_distance(emb1, emb2), rel=1e-5) == 5.0
    assert calc.compute_euclidean_distance(emb1, emb1) == 0.0
