import logging
import time
from dataclasses import dataclass
from typing import Any

from app.application.ports.face_detector import FaceDetectorPort
from app.application.ports.face_embedder import FaceEmbedderPort
from app.application.ports.liveness_detector import LivenessDetectorPort
from app.application.use_cases.check_liveness import CheckLivenessUseCase
from app.application.use_cases.detect_face import DetectFaceUseCase
from app.application.use_cases.extract_embedding import ExtractEmbeddingUseCase
from app.application.use_cases.verify_face import VerifyFaceUseCase
from app.domain.services.similarity import SimilarityCalculator
from app.infrastructure.adapters.insightface_detector import InsightFaceDetector
from app.infrastructure.adapters.insightface_embedder import InsightFaceEmbedder
from app.infrastructure.adapters.numpy_similarity_calculator import NumpySimilarityCalculator
from app.infrastructure.adapters.onnx_liveness_detector import OnnxLivenessDetector
from app.infrastructure.config.settings import AppSettings
from app.interfaces.grpc.server import GrpcServer
from app.interfaces.grpc.servicer import FaceServiceServicer


@dataclass
class ApplicationContainer:
    """Dependency injection container cho toàn bộ ứng dụng."""

    settings: AppSettings
    servicer: FaceServiceServicer
    server: GrpcServer
    detector: FaceDetectorPort | None = None
    embedder: FaceEmbedderPort | None = None
    liveness_detector: LivenessDetectorPort | None = None
    similarity_calculator: SimilarityCalculator | None = None
    detect_face_uc: DetectFaceUseCase | None = None
    extract_embedding_uc: ExtractEmbeddingUseCase | None = None
    verify_face_uc: VerifyFaceUseCase | None = None
    check_liveness_uc: CheckLivenessUseCase | None = None


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
            except (FileNotFoundError, RuntimeError) as exc:
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
    similarity_calculator = NumpySimilarityCalculator()

    detect_face_uc = DetectFaceUseCase(detector=detector)
    extract_embedding_uc = ExtractEmbeddingUseCase(
        embedder=embedder,
        detector=detector,
        liveness_detector=liveness_detector,
        validate_quality=True,
        require_single_face=True,
    )
    verify_face_uc = VerifyFaceUseCase(
        embedder=embedder,
        similarity_calculator=similarity_calculator,
        detector=detector,
        liveness_detector=liveness_detector,
        validate_quality=True,
        require_single_face=True,
    )
    check_liveness_uc = CheckLivenessUseCase(
        liveness_detector=liveness_detector,
        detector=detector,
    )

    servicer = FaceServiceServicer(
        detect_face_uc=detect_face_uc,
        extract_embedding_uc=extract_embedding_uc,
        verify_face_uc=verify_face_uc,
        check_liveness_uc=check_liveness_uc,
    )
    server = GrpcServer(settings=cfg, servicer=servicer)

    container = ApplicationContainer(
        settings=cfg,
        servicer=servicer,
        server=server,
        detector=detector,
        embedder=embedder,
        liveness_detector=liveness_detector,
        similarity_calculator=similarity_calculator,
        detect_face_uc=detect_face_uc,
        extract_embedding_uc=extract_embedding_uc,
        verify_face_uc=verify_face_uc,
        check_liveness_uc=check_liveness_uc,
    )

    if warmup:
        warmup_models(container)

    return container
