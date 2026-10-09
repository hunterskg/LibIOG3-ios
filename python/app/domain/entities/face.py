from __future__ import annotations

from dataclasses import dataclass, field
from typing import TYPE_CHECKING, Any

from app.domain.constants import (
    DEFAULT_MAX_BLUR,
    DEFAULT_MAX_PITCH,
    DEFAULT_MAX_ROLL,
    DEFAULT_MAX_YAW,
    DEFAULT_MIN_BLUR_SCORE,
    DEFAULT_MIN_FACE_SIZE,
)
from app.domain.exceptions.face_exceptions import LowFaceQualityException

if TYPE_CHECKING:
    from app.domain.value_objects.bounding_box import BoundingBox
    from app.domain.value_objects.embedding import FaceEmbedding
    from app.domain.value_objects.landmark import FaceLandmarks

"""
đại diện cho dữ liệu khuôn mặt, bao gồm vị trí (BoundingBox), điểm mốc (Landmarks), embedding, và các thông tin chất lượng ảnh như độ mờ và góc xoay.
 """


@dataclass
class Face:
    id: str
    bbox: BoundingBox
    landmarks: FaceLandmarks | None = None
    confidence: float = 0.0
    image_path: str | None = None
    blur_score: float | None = None
    pitch: float | None = None
    yaw: float | None = None
    roll: float | None = None

    def check_quality(
        self,
        max_blur: float = DEFAULT_MAX_BLUR,
        max_pitch: float = DEFAULT_MAX_PITCH,
        max_yaw: float = DEFAULT_MAX_YAW,
        min_blur: float = DEFAULT_MIN_BLUR_SCORE,
        min_face_size: float = DEFAULT_MIN_FACE_SIZE,
        max_roll: float = DEFAULT_MAX_ROLL,
    ) -> tuple[bool, list[str]]:
        """Kiểm tra chất lượng khuôn mặt: độ mờ (Laplacian variance), kích thước bbox, góc roll/pitch/yaw."""

        violations: list[str] = []

        # Kiểm tra độ mờ: Laplacian variance phải >= min_blur
        if self.blur_score is not None and self.blur_score < min_blur:
            violations.append(
                f"Ảnh quá mờ: Laplacian variance={self.blur_score:.2f} < ngưỡng {min_blur:.2f}"
            )

        # Kiểm tra kích thước khuôn mặt tối thiểu (>= min_face_size x min_face_size)
        if self.bbox.width < min_face_size or self.bbox.height < min_face_size:
            violations.append(
                f"Kích thước khuôn mặt quá nhỏ: {self.bbox.width:.1f}x{self.bbox.height:.1f} < {min_face_size:.1f}x{min_face_size:.1f}"
            )

        # Kiểm tra góc roll
        if self.roll is not None and abs(self.roll) > max_roll:
            violations.append(
                f"Góc roll vượt ngưỡng: roll={self.roll:.1f}° (|roll| > {max_roll:.1f}°)"
            )

        # Kiểm tra góc pitch
        if self.pitch is not None and abs(self.pitch) > max_pitch:
            violations.append(
                f"Góc pitch vượt ngưỡng: pitch={self.pitch:.1f}° (|pitch| > {max_pitch:.1f}°)"
            )

        # Kiểm tra góc yaw
        if self.yaw is not None and abs(self.yaw) > max_yaw:
            violations.append(f"Góc yaw vượt ngưỡng: yaw={self.yaw:.1f}° (|yaw| > {max_yaw:.1f}°)")

        return len(violations) == 0, violations

    def is_valid_quality(
        self,
        max_blur: float = DEFAULT_MAX_BLUR,
        max_pitch: float = DEFAULT_MAX_PITCH,
        max_yaw: float = DEFAULT_MAX_YAW,
        min_blur: float = DEFAULT_MIN_BLUR_SCORE,
        min_face_size: float = DEFAULT_MIN_FACE_SIZE,
        max_roll: float = DEFAULT_MAX_ROLL,
    ) -> bool:
        """Kiểm tra khuôn mặt đạt chuẩn chất lượng hay không."""
        valid, _ = self.check_quality(
            max_blur=max_blur,
            max_pitch=max_pitch,
            max_yaw=max_yaw,
            min_blur=min_blur,
            min_face_size=min_face_size,
            max_roll=max_roll,
        )
        return valid

    def validate_quality(
        self,
        max_blur: float = DEFAULT_MAX_BLUR,
        max_pitch: float = DEFAULT_MAX_PITCH,
        max_yaw: float = DEFAULT_MAX_YAW,
        min_blur: float = DEFAULT_MIN_BLUR_SCORE,
        min_face_size: float = DEFAULT_MIN_FACE_SIZE,
        max_roll: float = DEFAULT_MAX_ROLL,
    ) -> None:
        """Ném LowFaceQualityException khi vi phạm ngưỡng chất lượng."""
        valid, violations = self.check_quality(
            max_blur=max_blur,
            max_pitch=max_pitch,
            max_yaw=max_yaw,
            min_blur=min_blur,
            min_face_size=min_face_size,
            max_roll=max_roll,
        )

        if not valid:
            raise LowFaceQualityException("; ".join(violations))


@dataclass
class FaceProfile:
    id: str
    embedding: FaceEmbedding
    metadata: dict[str, Any] = field(default_factory=dict)


DetectedFace = Face
