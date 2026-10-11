from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Any, Protocol, runtime_checkable


class SpoofDetectedException(Exception):
    """Phát hiện giả mạo khuôn mặt."""


class LivenessStatus(Enum):
    UNKNOWN = 0
    REAL = 1
    SPOOF = 2


@dataclass
class LivenessResult:
    is_live: bool
    status: LivenessStatus
    confidence: float
    details: dict[str, Any] | None = None


@runtime_checkable
class LivenessDetectorPort(Protocol):
    """Port kiểm tra liveness (xác thực người thật vs giả mạo)."""

    def check_liveness(self, image_bytes: bytes) -> LivenessResult:
        raise NotImplementedError
