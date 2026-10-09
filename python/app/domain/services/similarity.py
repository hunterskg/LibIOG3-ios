from __future__ import annotations

from typing import Protocol, runtime_checkable

from app.domain.value_objects.embedding import FaceEmbedding


@runtime_checkable
class SimilarityCalculator(Protocol):
    """Protocol tính toán độ tương đồng giữa các FaceEmbedding.

    Với embedding đã được L2-normalized, Cosine Similarity tương đương tích vô hướng
    (Dot Product) của 2 vector đơn vị: Cosine(u, v) = u . v.
    """

    # Dùng khi model được huấn luyện để tính toán độ tương đồng giữa các embedding vector của khuôn mặt.
    def compute_cosine_similarity(self, emb1: FaceEmbedding, emb2: FaceEmbedding) -> float:
        """Tính Cosine Similarity giữa 2 embedding (tương đương Dot Product khi cả 2 vector đã L2-normalized)."""
        ...

    # Dùng khi model được huấn luyện để tính toán khoảng cách Euclidean giữa các embedding vector của khuôn mặt.
    def compute_euclidean_distance(self, emb1: FaceEmbedding, emb2: FaceEmbedding) -> float:
        """Tính khoảng cách Euclidean giữa 2 embedding."""
        ...
