from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Protocol, runtime_checkable

import numpy as np

from app.ports.face_detector import BoundingBox, FaceLandmarks

_L2_EPSILON: float = 1e-12


class EmbeddingMismatchException(Exception):
    """Vector embedding không khớp số chiều hoặc không tương thích."""


@dataclass(frozen=True)
class FaceEmbedding:
    values: tuple[float, ...]
    dimension: int

    def __post_init__(self) -> None:
        if len(self.values) != self.dimension:
            raise ValueError(
                f"Embedding values count {len(self.values)} does not match dimension {self.dimension}"
            )

    def as_vector(self) -> list[float]:
        return list(self.values)

    def l2_normalize(self) -> FaceEmbedding:
        norm: float = float(np.linalg.norm(self.values)) + _L2_EPSILON
        normalized: tuple[float, ...] = tuple(v / norm for v in self.values)
        return FaceEmbedding(values=normalized, dimension=self.dimension)

    def is_l2_normalized(self, tolerance: float = 1e-3) -> bool:
        norm: float = float(np.linalg.norm(self.values))
        return abs(norm - 1.0) <= tolerance

    def cosine_similarity(self, other: FaceEmbedding) -> float:
        """Tính Cosine Similarity với vector FaceEmbedding khác."""
        if self.dimension != other.dimension or len(self.values) != len(other.values):
            raise EmbeddingMismatchException(
                f"Kích thước embedding không khớp: {len(self.values)} != {len(other.values)}"
            )

        v1 = np.asarray(self.values, dtype=np.float32)
        v2 = np.asarray(other.values, dtype=np.float32)

        norm1 = float(np.linalg.norm(v1))
        norm2 = float(np.linalg.norm(v2))
        if norm1 == 0.0 or norm2 == 0.0:
            return 0.0

        v1_norm = v1 / (norm1 + _L2_EPSILON)
        v2_norm = v2 / (norm2 + _L2_EPSILON)

        similarity = float(np.dot(v1_norm, v2_norm))
        return float(np.clip(similarity, -1.0, 1.0))


@runtime_checkable
class FaceEmbedderPort(Protocol):
    """Port trích xuất embedding từ khuôn mặt."""

    def extract_embedding(
        self,
        image_bytes: bytes,
        bbox: BoundingBox | None = None,
        landmarks: Any = None,
    ) -> FaceEmbedding:
        raise NotImplementedError
