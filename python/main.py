import logging
import signal
import sys
import threading
from typing import Any

from app.infrastructure.config.settings import AppSettings
from bootstrap import ApplicationContainer, bootstrap_app

logger = logging.getLogger("face_service")


def setup_logging(level: str = "INFO") -> None:
    """Thiết lập logging định dạng chuẩn cho toàn bộ tiến trình."""
    logging.basicConfig(
        level=getattr(logging, level.upper(), logging.INFO),
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        force=True,
    )


def run_server(settings: AppSettings | None = None) -> ApplicationContainer:
    """Khởi chạy gRPC server với warmup và đăng ký graceful shutdown."""
    cfg = settings or AppSettings()
    setup_logging(cfg.log_level)

    container = bootstrap_app(settings=cfg, warmup=cfg.warmup_on_startup)
    server = container.server
    shutdown_event = threading.Event()

    def shutdown_handler(sig: int, frame: Any) -> None:
        if shutdown_event.is_set():
            logger.info("Shutdown already in progress, ignoring signal %s", sig)
            return
        shutdown_event.set()
        logger.info(
            "Received signal %s, initiating graceful shutdown (grace=%.1fs)...",
            sig,
            cfg.grpc_grace_period,
        )
        server.stop(grace=cfg.grpc_grace_period)
        logger.info("Server stopped gracefully")

    signal.signal(signal.SIGINT, shutdown_handler)
    if hasattr(signal, "SIGTERM"):
        signal.signal(signal.SIGTERM, shutdown_handler)

    logger.info("Starting gRPC server on %s", cfg.server_address())
    server.start()

    try:
        server.wait_for_termination()
    except KeyboardInterrupt:
        logger.info("KeyboardInterrupt received in main loop")
        shutdown_handler(signal.SIGINT, None)

    return container


def main() -> None:
    """Entry point chính khi chạy qua CLI / Docker container."""
    try:
        run_server()
    except Exception as exc:
        logger.critical("Fatal error starting server: %s", exc, exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
