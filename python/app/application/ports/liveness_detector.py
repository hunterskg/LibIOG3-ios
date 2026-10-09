from typing import Protocol, runtime_checkable

from app.domain.entities.liveness import LivenessResult


@runtime_checkable
class LivenessDetectorPort(Protocol):
    """Port kiểm tra liveness (xác thực người thật vs giả mạo)."""

    def check_liveness(self, image_bytes: bytes) -> LivenessResult:
        """Kiểm tra liveness cho ảnh.

        Args:
            image_bytes: Dữ liệu ảnh (JPEG, PNG, etc.)

        Returns:
            LivenessResult chứa trạng thái và độ tin cậy.

        Raises:
            NotImplementedError: Khi subclass chưa triển khai.
        """
        raise NotImplementedError
