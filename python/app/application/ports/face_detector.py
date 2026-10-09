from typing import Protocol, runtime_checkable

from app.domain.entities.face import Face


@runtime_checkable
class FaceDetectorPort(Protocol):
    """Port nhận diện và trả về danh sách khuôn mặt trong ảnh."""

    def detect(self, image_bytes: bytes) -> list[Face]:
        """Nhận diện khuôn mặt từ bytes ảnh.

        Args:
            image_bytes: Dữ liệu ảnh (JPEG, PNG, etc.)

        Returns:
            Danh sách các đối tượng Face chứa bbox và landmarks nếu có.

        Raises:
            NotImplementedError: Khi subclass chưa triển khai.
        """
        raise NotImplementedError
