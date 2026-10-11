from typing import Any

import cv2
import numpy as np

from app.ports.face_detector import BoundingBox
from app.ports.face_embedder import FaceEmbedderPort, FaceEmbedding

# Ma trận tọa độ landmark đích chuẩn ArcFace / InsightFace (112x112 px)
ARCFACE_DST_112: np.ndarray = np.array(
    [
        [38.2946, 51.6963],  # 1. Mắt trái (Left Eye)
        [73.5318, 51.5014],  # 2. Mắt phải (Right Eye)
        [56.0252, 71.7366],  # 3. Đỉnh mũi (Nose Tip)
        [41.5493, 92.3655],  # 4. Khóe miệng trái (Left Mouth Corner)
        [70.7299, 92.2041],  # 5. Khóe miệng phải (Right Mouth Corner)
    ],
    dtype=np.float32,
)


class InsightFaceEmbedder(FaceEmbedderPort):
    """Adapter trích xuất feature vector 512 chiều sử dụng InsightFace/ArcFace."""

    def __init__(
        self,
        model_path: str = "models/w600k_r50.onnx",
        model_name: str = "buffalo_l",
        embedding_dim: int = 512,
        model_root: str | None = None,
        recognizer: Any = None,
    ) -> None:
        self._model_path = model_path
        self._model_name = model_name
        self._embedding_dim = embedding_dim
        self._model_root = model_root
        self._recognizer = recognizer

    def _get_recognizer(self) -> Any:
        # ponytail: lazy load model nhận diện qua model_zoo khi recognizer chưa được inject
        if self._recognizer is None:
            import os

            from insightface.model_zoo import get_model

            model_path = self._model_path
            kwargs: dict[str, Any] = {}
            if self._model_root:
                kwargs["root"] = self._model_root
            if not os.path.isfile(model_path):
                default_path = os.path.expanduser(
                    f"~/.insightface/models/{self._model_name}/w600k_r50.onnx"
                )
                if os.path.isfile(default_path):
                    model_path = default_path
            rec = get_model(model_path, **kwargs)
            if hasattr(rec, "prepare"):
                rec.prepare(ctx_id=0)
            self._recognizer = rec
        return self._recognizer

    def warmup(self) -> None:
        """Load ArcFace recognizer và chạy 1 lần dummy feature extraction."""
        rec = self._get_recognizer()
        dummy_face = np.zeros((112, 112, 3), dtype=np.uint8)
        if hasattr(rec, "get_feat"):
            rec.get_feat(dummy_face)
        elif hasattr(rec, "get"):
            rec.get(dummy_face)
        elif callable(rec):
            rec(dummy_face)

    def extract_embedding(
        self,
        image_bytes: bytes,
        bbox: BoundingBox | None = None,
        landmarks: Any = None,
    ) -> FaceEmbedding:
        if not image_bytes:
            raise ValueError("Empty image bytes")

        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if img is None:
            raise ValueError("Invalid or corrupted image format")

        face_img: np.ndarray | None = None

        if landmarks is not None and hasattr(landmarks, "points") and len(landmarks.points) >= 5:
            kps = np.array([[pt.x, pt.y] for pt in landmarks.points[:5]], dtype=np.float32)
            try:
                from insightface.utils import face_align

                face_img = face_align.norm_crop(img, landmark=kps, image_size=112)
            except Exception:
                affine_matrix, _ = cv2.estimateAffinePartial2D(kps, ARCFACE_DST_112)
                if affine_matrix is not None:
                    face_img = cv2.warpAffine(
                        img,
                        affine_matrix,
                        (112, 112),
                        borderMode=cv2.BORDER_CONSTANT,
                        borderValue=0.0,
                    )

        if face_img is None:
            if bbox is not None:
                h, w = img.shape[:2]
                cx = bbox.x + bbox.width / 2.0
                cy = bbox.y + bbox.height / 2.0
                side = max(bbox.width, bbox.height) * 1.2
                x1 = max(0, int(cx - side / 2.0))
                y1 = max(0, int(cy - side / 2.0))
                x2 = min(w, int(cx + side / 2.0))
                y2 = min(h, int(cy + side / 2.0))
                cropped = img[y1:y2, x1:x2]
                if cropped.size > 0:
                    face_img = cv2.resize(cropped, (112, 112))
                else:
                    face_img = cv2.resize(img, (112, 112))
            else:
                face_img = cv2.resize(img, (112, 112))

        recognizer = self._get_recognizer()
        if hasattr(recognizer, "get_feat"):
            raw_feat1 = recognizer.get_feat(face_img)
            face_img_flip = cv2.flip(face_img, 1)
            raw_feat2 = recognizer.get_feat(face_img_flip)
            raw_feat = raw_feat1 + raw_feat2
        elif hasattr(recognizer, "get"):
            raw_feat = recognizer.get(face_img)
        elif callable(recognizer):
            raw_feat = recognizer(face_img)
        else:
            raise RuntimeError("Recognizer does not support feature extraction")

        vec = np.squeeze(np.asarray(raw_feat, dtype=np.float32))
        if vec.ndim != 1 or len(vec) != self._embedding_dim:
            raise ValueError(
                f"Extracted embedding dimension {len(vec)} does not match {self._embedding_dim}"
            )

        norm = float(np.linalg.norm(vec))
        normed = vec / (norm + 1e-12)

        return FaceEmbedding(
            values=tuple(float(v) for v in normed),
            dimension=self._embedding_dim,
        )
