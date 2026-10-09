from typing import Any, Protocol, runtime_checkable

from app.domain.value_objects.bounding_box import BoundingBox
from app.domain.value_objects.embedding import FaceEmbedding


@runtime_checkable
class FaceEmbedderPort(Protocol):
    """Port trích xuất embedding từ khuôn mặt."""

    def extract_embedding(
        self,
        image_bytes: bytes,
        bbox: BoundingBox | None = None,
        landmarks: Any = None,
    ) -> FaceEmbedding:
        """Trích xuất embedding từ khuôn mặt hoặc toàn bộ ảnh nếu bbox=None.

        Args:
            image_bytes: Dữ liệu ảnh (JPEG, PNG, etc.)
            bbox: Khuôn mặt cần trích xuất (nếu có).
            landmarks: Điểm mốc khuôn mặt (5 landmarks) phục vụ căn chỉnh chuẩn (Face Alignment).

        Returns:
            FaceEmbedding chứa vector và thông tin kích thước.

        Raises:
            NotImplementedError: Khi subclass chưa triển khai.
        """
        raise NotImplementedError
