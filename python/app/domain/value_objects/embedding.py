from __future__ import annotations

from dataclasses import dataclass

import numpy as np

"""
- Đại diện cho embedding vector của khuôn mặt, bao gồm:
- values: tuple[float, ...], giá trị embedding vector
- dimension: int, số chiều của embedding vector
- Phương thức as_vector() trả về embedding dưới dạng list[float]
 """

# Hằng số epsilon an toàn, tránh chia cho 0 trong L2 normalization.
_L2_EPSILON: float = 1e-12


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
        """Trả về FaceEmbedding mới đã chuẩn hóa L2 norm: v / ||v||_2."""
        norm: float = float(np.linalg.norm(self.values)) + _L2_EPSILON
        normalized: tuple[float, ...] = tuple(v / norm for v in self.values)
        return FaceEmbedding(values=normalized, dimension=self.dimension)

    def is_l2_normalized(self, tolerance: float = 1e-3) -> bool:
        """Kiểm tra vector đã có L2 norm ~ 1.0 trong khoảng sai số tolerance."""
        norm: float = float(np.linalg.norm(self.values))
        return abs(norm - 1.0) <= tolerance
