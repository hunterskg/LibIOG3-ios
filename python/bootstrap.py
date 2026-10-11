import logging
import time
from dataclasses import dataclass
from typing import Any

from app.infrastructure.adapters.insightface_detector import InsightFaceDetector
from app.infrastructure.adapters.insightface_embedder import InsightFaceEmbedder
from app.infrastructure.adapters.onnx_liveness_detector import OnnxLivenessDetector
from app.infrastructure.config.settings import AppSettings
from app.interfaces.grpc.server import GrpcServer
from app.interfaces.grpc.servicer import FaceServiceServicer
from app.ports.face_detector import FaceDetectorPort
from app.ports.face_embedder import FaceEmbedderPort
from app.ports.liveness_detector import LivenessDetectorPort


@dataclass
class ApplicationContainer:
    """Dependency injection container cho toàn bộ ứng dụng."""

    settings: AppSettings
    servicer: FaceServiceServicer
    server: GrpcServer
    detector: FaceDetectorPort | None = None
    embedder: FaceEmbedderPort | None = None
    liveness_detector: LivenessDetectorPort | None = None


logger = logging.getLogger("face_service")


def warmup_models(container: ApplicationContainer) -> None:
    """Khởi tạo và chạy dummy inference cho tất cả models trong container."""
    total_start = time.perf_counter()
    logger.info("Starting model warm-up...")

    targets: list[tuple[str, Any]] = [
        ("face detector", container.detector),
        ("face embedder", container.embedder),
        ("liveness detector", container.liveness_detector),
    ]

    for name, adapter in targets:
        if adapter is not None and hasattr(adapter, "warmup") and callable(adapter.warmup):
            step_start = time.perf_counter()
            try:
                adapter.warmup()
                elapsed = (time.perf_counter() - step_start) * 1000.0
                logger.info("Warming up %s... done (%.1f ms)", name, elapsed)
            except Exception as exc:
                elapsed = (time.perf_counter() - step_start) * 1000.0
                logger.warning("Warming up %s failed (%.1f ms): %s", name, elapsed, exc)

    total_elapsed = (time.perf_counter() - total_start) * 1000.0
    logger.info("Model warm-up completed in total (%.1f ms)", total_elapsed)


def bootstrap_app(
    settings: AppSettings | None = None,
    warmup: bool = False,
) -> ApplicationContainer:
    """Khởi tạo cấu hình và dependency injection container."""
    cfg = settings or AppSettings()

    detector = InsightFaceDetector(
        model_name=cfg.insightface_model_name,
        model_root=cfg.model_root_dir,
    )
    embedder = InsightFaceEmbedder(
        model_path=cfg.embedder_model_path,
        model_name=cfg.insightface_model_name,
        model_root=cfg.model_root_dir,
    )
    liveness_detector = OnnxLivenessDetector(
        model_path=cfg.liveness_model_path,
        threshold=cfg.liveness_threshold,
        input_size=cfg.liveness_input_size,
    )

    servicer = FaceServiceServicer(
        detector=detector,
        embedder=embedder,
        liveness_detector=liveness_detector,
        validate_quality=True,
        require_single_face=True,
    )
    server = GrpcServer(settings=cfg, servicer=servicer)

    container = ApplicationContainer(
        settings=cfg,
        servicer=servicer,
        server=server,
        detector=detector,
        embedder=embedder,
        liveness_detector=liveness_detector,
    )

    if warmup:
        warmup_models(container)

    return container
