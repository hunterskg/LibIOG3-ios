from __future__ import annotations

import numpy as np

from app.domain.exceptions.face_exceptions import EmbeddingMismatchException
from app.domain.services.similarity import SimilarityCalculator
from app.domain.value_objects.embedding import FaceEmbedding


class NumpySimilarityCalculator(SimilarityCalculator):
    """Hiện thực SimilarityCalculator dùng NumPy tối ưu hóa hiệu năng."""

    """ 
    - Cosine Similarity: đo lường mức độ tương đồng về hướng giữa hai vector, 
        giá trị nằm trong khoảng [-1, 1], với 1 là hoàn toàn giống nhau, 
        0 là không tương quan, 
        và -1 là hoàn toàn ngược nhau.
    """

    def compute_cosine_similarity(self, emb1: FaceEmbedding, emb2: FaceEmbedding) -> float:
        """Tính Cosine Similarity giữa 2 embedding qua NumPy (tương đương dot product khi L2-normalized)."""
        if emb1.dimension != emb2.dimension or len(emb1.values) != len(emb2.values):
            raise EmbeddingMismatchException(
                f"Kích thước embedding không khớp: {len(emb1.values)} != {len(emb2.values)}"
            )

        # Chuyển đổi embedding sang mảng NumPy
        v1 = np.asarray(emb1.values, dtype=np.float32)
        v2 = np.asarray(emb2.values, dtype=np.float32)

        norm1 = float(np.linalg.norm(v1))
        norm2 = float(np.linalg.norm(v2))
        # ponytail: norm == 0 trả 0.0 thay vì ném exception; nâng cấp khi cần strict zero-vector handling
        if norm1 == 0.0 or norm2 == 0.0:
            return 0.0

        v1_norm = v1 / (norm1 + 1e-12)
        v2_norm = v2 / (norm2 + 1e-12)

        # Dot product của 2 vector đã L2 normalized
        similarity = float(np.dot(v1_norm, v2_norm))
        return float(np.clip(similarity, -1.0, 1.0))

    """ 
    - Euclidean Distance: đo lường khoảng cách "thẳng" giữa hai điểm trong không gian vector,
        giá trị luôn >= 0, với 0 là hai vector trùng nhau.
        Về nhận diện khuôn mặt, khoảng cách Euclidean nhỏ hơn ngưỡng nhất định thường được coi là cùng một người.
    """

    def compute_euclidean_distance(self, emb1: FaceEmbedding, emb2: FaceEmbedding) -> float:
        """Tính khoảng cách Euclidean giữa 2 embedding qua NumPy."""
        if emb1.dimension != emb2.dimension or len(emb1.values) != len(emb2.values):
            raise EmbeddingMismatchException(
                f"Kích thước embedding không khớp: {len(emb1.values)} != {len(emb2.values)}"
            )

        # Chuyển đổi embedding sang mảng NumPy
        v1 = np.asarray(emb1.values, dtype=np.float32)
        v2 = np.asarray(emb2.values, dtype=np.float32)

        # Khoảng cách Euclidean: ||v1 - v2|| = sqrt(sum((v1_i - v2_i)^2))
        return float(np.linalg.norm(v1 - v2))
