from typing import Any
from uuid import uuid4

import cv2
import numpy as np

from app.application.ports.face_detector import FaceDetectorPort
from app.domain.entities.face import Face
from app.domain.value_objects.bounding_box import BoundingBox
from app.domain.value_objects.landmark import FaceLandmarks, Point2D


class InsightFaceDetector(FaceDetectorPort):
    """Adapter nhận diện khuôn mặt sử dụng InsightFace/SCRFD."""

    def __init__(
        self,
        model_name: str = "buffalo_l",
        model_root: str | None = None,
        det_thresh: float = 0.5,
        det_size: tuple[int, int] = (640, 640),
        app: Any = None,
    ) -> None:
        self._model_name = model_name
        self._model_root = model_root
        self._det_thresh = det_thresh
        self._det_size = det_size
        self._app = app

    def _get_app(self) -> Any:
        # ponytail: lazy load FaceAnalysis khi app chưa được inject để tránh load model khi init
        if self._app is None:
            from insightface.app import FaceAnalysis

            kwargs: dict[str, Any] = {
                "name": self._model_name,
                "allowed_modules": ["detection"],
            }
            if self._model_root:
                kwargs["root"] = self._model_root
            app = FaceAnalysis(**kwargs)
            app.prepare(ctx_id=0, det_thresh=self._det_thresh, det_size=self._det_size)
            self._app = app
        return self._app

    def warmup(self) -> None:
        """Load model vào memory và chạy 1 lần dummy inference để compile engine."""
        app = self._get_app()
        dummy_frame = np.zeros((640, 640, 3), dtype=np.uint8)
        app.get(dummy_frame)

    def detect(self, image_bytes: bytes) -> list[Face]:
        if not image_bytes:
            raise ValueError("Empty image bytes")

        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if img is None:
            raise ValueError("Invalid or corrupted image format")

        app = self._get_app()
        raw_faces = app.get(img)

        faces: list[Face] = []
        for f in raw_faces:
            raw_bbox = getattr(f, "bbox", None) if not isinstance(f, dict) else f.get("bbox")
            score_raw = (
                getattr(f, "det_score", None) if not isinstance(f, dict) else f.get("det_score")
            )
            if score_raw is None:
                score_raw = (
                    getattr(f, "score", 0.0) if not isinstance(f, dict) else f.get("score", 0.0)
                )
            score_val = float(score_raw if score_raw is not None else 0.0)

            if raw_bbox is None:
                continue

            x1, y1, x2, y2 = (
                float(raw_bbox[0]),
                float(raw_bbox[1]),
                float(raw_bbox[2]),
                float(raw_bbox[3]),
            )
            bbox = BoundingBox(
                x=x1,
                y=y1,
                width=max(0.0, x2 - x1),
                height=max(0.0, y2 - y1),
                confidence=score_val,
            )

            raw_kps = getattr(f, "kps", None) if not isinstance(f, dict) else f.get("kps")
            landmarks: FaceLandmarks | None = None
            if raw_kps is not None:
                landmarks = FaceLandmarks(
                    points=tuple(
                        Point2D(x=float(pt[0]), y=float(pt[1]), index=idx)
                        for idx, pt in enumerate(raw_kps)
                    )
                )

            raw_pose = getattr(f, "pose", None) if not isinstance(f, dict) else f.get("pose")
            pitch: float | None = None
            yaw: float | None = None
            roll: float | None = None

            if raw_pose is not None and len(raw_pose) >= 3:
                pitch = float(raw_pose[0])
                yaw = float(raw_pose[1])
                roll = float(raw_pose[2])
            else:
                p = getattr(f, "pitch", None) if not isinstance(f, dict) else f.get("pitch")
                y = getattr(f, "yaw", None) if not isinstance(f, dict) else f.get("yaw")
                r = getattr(f, "roll", None) if not isinstance(f, dict) else f.get("roll")
                pitch = float(p) if p is not None else None
                yaw = float(y) if y is not None else None
                roll = float(r) if r is not None else None

            # Tính Laplacian variance trên vùng crop khuôn mặt để làm blur_score
            img_h, img_w = img.shape[:2]
            cx1 = max(0, int(x1))
            cy1 = max(0, int(y1))
            cx2 = min(img_w, int(x2))
            cy2 = min(img_h, int(y2))
            blur_score: float | None = None
            if cx2 > cx1 and cy2 > cy1:
                crop = img[cy1:cy2, cx1:cx2]
                if crop.size > 0:
                    gray_crop = cv2.cvtColor(crop, cv2.COLOR_BGR2GRAY)
                    blur_score = float(cv2.Laplacian(gray_crop, cv2.CV_64F).var())

            faces.append(
                Face(
                    id=str(uuid4()),
                    bbox=bbox,
                    landmarks=landmarks,
                    confidence=score_val,
                    blur_score=blur_score,
                    pitch=pitch,
                    yaw=yaw,
                    roll=roll,
                )
            )

        return faces
