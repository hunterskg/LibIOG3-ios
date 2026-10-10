from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol, runtime_checkable

DEFAULT_MAX_BLUR: float = 0.5
DEFAULT_MIN_BLUR_SCORE: float = 100.0
DEFAULT_MIN_FACE_SIZE: float = 80.0
DEFAULT_MAX_PITCH: float = 20.0
DEFAULT_MAX_YAW: float = 20.0
DEFAULT_MAX_ROLL: float = 20.0


class FaceServiceException(Exception):
    """Base exception cho Face Service."""


class FaceNotFoundException(FaceServiceException):
    """Không tìm thấy khuôn mặt trong ảnh."""


class MultipleFacesDetectedException(FaceServiceException):
    """Phát hiện nhiều hơn số khuôn mặt cho phép."""


class LowFaceQualityException(FaceServiceException):
    """Chất lượng khuôn mặt không đạt yêu cầu."""


@dataclass(frozen=True)
class BoundingBox:
    x: float
    y: float
    width: float
    height: float
    confidence: float = 0.0

    def area(self) -> float:
        return max(0.0, self.width * self.height)

    def to_xyxy(self) -> tuple[float, float, float, float]:
        return (self.x, self.y, self.x + self.width, self.y + self.height)

    @classmethod
    def from_xyxy(
        cls, x1: float, y1: float, x2: float, y2: float, confidence: float = 0.0
    ) -> BoundingBox:
        return cls(
            x=x1,
            y=y1,
            width=max(0.0, x2 - x1),
            height=max(0.0, y2 - y1),
            confidence=confidence,
        )


@dataclass(frozen=True)
class Point2D:
    x: float
    y: float
    index: int = 0


@dataclass(frozen=True)
class FaceLandmarks:
    points: tuple[Point2D, ...]

    def count(self) -> int:
        return len(self.points)


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
        violations: list[str] = []
        if self.blur_score is not None and self.blur_score < min_blur:
            violations.append(f"Blur score {self.blur_score:.1f} < min {min_blur:.1f}")
        if self.pitch is not None and abs(self.pitch) > max_pitch:
            violations.append(f"Pitch {self.pitch:.1f} exceeds max {max_pitch:.1f}")
        if self.yaw is not None and abs(self.yaw) > max_yaw:
            violations.append(f"Yaw {self.yaw:.1f} exceeds max {max_yaw:.1f}")
        if self.roll is not None and abs(self.roll) > max_roll:
            violations.append(f"Roll {self.roll:.1f} exceeds max {max_roll:.1f}")
        if self.bbox.width < min_face_size or self.bbox.height < min_face_size:
            violations.append(f"Face size {self.bbox.width}x{self.bbox.height} < min {min_face_size}")
        return len(violations) == 0, violations

    def validate_quality(
        self,
        max_blur: float = DEFAULT_MAX_BLUR,
        max_pitch: float = DEFAULT_MAX_PITCH,
        max_yaw: float = DEFAULT_MAX_YAW,
        min_blur: float = DEFAULT_MIN_BLUR_SCORE,
        min_face_size: float = DEFAULT_MIN_FACE_SIZE,
        max_roll: float = DEFAULT_MAX_ROLL,
    ) -> None:
        ok, violations = self.check_quality(
            max_blur=max_blur,
            max_pitch=max_pitch,
            max_yaw=max_yaw,
            min_blur=min_blur,
            min_face_size=min_face_size,
            max_roll=max_roll,
        )
        if not ok:
            raise LowFaceQualityException("; ".join(violations))


@runtime_checkable
class FaceDetectorPort(Protocol):
    """Port nhận diện khuôn mặt."""

    def detect(self, image_bytes: bytes) -> list[Face]:
        raise NotImplementedError
