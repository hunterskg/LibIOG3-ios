from dataclasses import dataclass
from enum import Enum
from typing import Any


class LivenessStatus(Enum):
    UNKNOWN = 0
    REAL = 1
    SPOOF = 2


""" 
Đai diện cho kết quả kiểm tra liveness của khuôn mặt
Bao gồm:
- is_live: bool, True nếu khuôn mặt là thật, False nếu là mặt giả
- status: LivenessStatus, trạng thái liveness (REAL, SPOOF, UNKNOWN)
   + REAL: khuôn mặt thật
   + SPOOF: khuôn mặt giả (ví dụ: ảnh, video, mặt nạo)
   + UNKNOWN: không xác định được
- confidence: float, độ tin cậy của kết quả (0.0 - 1.0)
- details: dict, thông tin chi tiết bổ sung (ví dụ: threshold, logits, softmax score)
 """


@dataclass
class LivenessResult:
    is_live: bool
    status: LivenessStatus
    confidence: float
    details: dict[str, Any] | None = None
