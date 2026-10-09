class FaceDomainException(Exception):
    """Base exception cho Face Domain."""


class FaceNotFoundException(FaceDomainException):
    """Ném ra khi không tìm thấy khuôn mặt trong ảnh."""


class MultipleFacesDetectedException(FaceDomainException):
    """Ném ra khi phát hiện nhiều khuôn mặt hơn giới hạn cho phép."""


class LowFaceQualityException(FaceDomainException):
    """Ném ra khi chất lượng khuôn mặt quá thấp."""


class SpoofDetectedException(FaceDomainException):
    """Ném ra khi phát hiện hành vi giả mạo (spoof)."""


class EmbeddingMismatchException(FaceDomainException):
    """Ném ra khi vector embedding không khớp số chiều hoặc không tương thích."""
