import logging
from pathlib import Path
from typing import Any

import cv2
import numpy as np

from app.ports.liveness_detector import (
    LivenessDetectorPort,
    LivenessResult,
    LivenessStatus,
)

logger = logging.getLogger("face_service")


class OnnxLivenessDetector(LivenessDetectorPort):
    """Adapter phát hiện giả mạo (liveness) sử dụng ONNX Runtime."""

    def __init__(
        self,
        model_path: str = "models/liveness.onnx",
        threshold: float = 0.80,
        input_size: tuple[int, int] = (80, 80),
        session: Any = None,
    ) -> None:
        self._model_path = model_path
        self._threshold = threshold
        self._input_size = input_size
        self._session = session

    def _get_session(self) -> Any:
        # ponytail: lazy load InferenceSession khi chưa được inject session mock
        if self._session is None:
            if not Path(self._model_path).is_file():
                return None
            import onnxruntime as ort

            self._session = ort.InferenceSession(
                self._model_path,
                providers=["CPUExecutionProvider"],
            )
        return self._session

    def warmup(self) -> None:
        """Khởi tạo ONNX Runtime session và chạy 1 lần dummy inference."""
        session = self._get_session()
        if session is None:
            logger.warning("Liveness model not found at %s, skipping warmup", self._model_path)
            return
        dummy_tensor = np.zeros((1, 3, *self._input_size), dtype=np.float32)
        input_name = "input"
        if hasattr(session, "get_inputs") and session.get_inputs():
            input_name = session.get_inputs()[0].name
        session.run(None, {input_name: dummy_tensor})

    def check_liveness(self, image_bytes: bytes) -> LivenessResult:
        if not image_bytes:
            raise ValueError("Empty image bytes")

        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if img is None:
            raise ValueError("Invalid or corrupted image format")

        session = self._get_session()
        if session is None:
            # ponytail: fallback REAL khi chưa có model liveness.onnx trên disk; nâng cấp khi có model
            logger.warning(
                "Liveness model not found at %s. Returning default REAL status.",
                self._model_path,
            )
            return LivenessResult(
                is_live=True,
                status=LivenessStatus.REAL,
                confidence=1.0,
                details={"fallback": True, "reason": "model_file_missing"},
            )

        resized = cv2.resize(img, self._input_size)
        tensor = np.transpose(resized, (2, 0, 1))
        tensor = np.expand_dims(tensor, axis=0).astype(np.float32) / 255.0

        session = self._get_session()
        input_name = "input"
        if hasattr(session, "get_inputs"):
            inputs = session.get_inputs()
            if inputs:
                input_name = inputs[0].name

        outputs = session.run(None, {input_name: tensor})
        raw_out = np.squeeze(np.asarray(outputs[0], dtype=np.float32))

        if raw_out.ndim == 0:
            p_real = float(raw_out)
        elif len(raw_out) == 1:
            p_real = float(raw_out[0])
        else:
            exp_scores = np.exp(raw_out - np.max(raw_out))
            probs = exp_scores / np.sum(exp_scores)
            p_real = float(probs[1])

        is_live = p_real >= self._threshold
        status = LivenessStatus.REAL if is_live else LivenessStatus.SPOOF

        return LivenessResult(
            is_live=is_live,
            status=status,
            confidence=p_real,
            details={"real_score": p_real, "threshold": self._threshold},
        )
