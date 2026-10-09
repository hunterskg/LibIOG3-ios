from dataclasses import dataclass


@dataclass(frozen=True)
class Point2D:
    x: float
    y: float
    index: int = 0


""" 
Đai diện cho tập hợp các điểm landmark của khuôn mặt (đây là vùng định vị chi tiết nét mặt), bao gồm:
- points: tuple[Point2D, ...], danh sách các điểm landmark (x, y) với chỉ số index (0-based)
- count(): trả về số lượng điểm landmark
 """


@dataclass(frozen=True)
class FaceLandmarks:
    points: tuple[Point2D, ...]

    def count(self) -> int:
        return len(self.points)
