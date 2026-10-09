from dataclasses import dataclass

""" 
- Đại diện cho bounding box của khuôn mặt trong ảnh:
- x, y: tọa độ góc trên bên trái của bounding box (tính theo tỷ lệ 0.0 - 1.0)
- width, height: chiều rộng và chiều cao của bounding box (tính theo tỷ lệ 0.0 - 1.0)
- confidence: độ tin cậy của bounding box (được mô hình dự đoán, 0.0 - 1.0)
 """


@dataclass(frozen=True)
class BoundingBox:
    x: float
    y: float
    width: float
    height: float
    confidence: float = 0.0

    # Tính diện tích bounding box (tỷ lệ 0.0 - 1.0)
    def area(self) -> float:
        return max(0.0, self.width * self.height)

    # Chuyển đổi bounding box sang định dạng (x1, y1, x2, y2)
    def to_xyxy(self) -> tuple[float, float, float, float]:
        return (self.x, self.y, self.x + self.width, self.y + self.height)

    # Chuyển đổi bounding box sang định dạng (x, y, width, height)
    @classmethod
    def from_xyxy(
        cls, x1: float, y1: float, x2: float, y2: float, confidence: float = 0.0
    ) -> "BoundingBox":
        return cls(
            x=x1,
            y=y1,
            width=max(0.0, x2 - x1),
            height=max(0.0, y2 - y1),
            confidence=confidence,
        )
