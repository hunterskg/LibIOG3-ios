from concurrent.futures import ThreadPoolExecutor

import grpc

from app.infrastructure.config.settings import AppSettings
from app.interfaces.grpc.interceptors.error_interceptor import GrpcErrorInterceptor
from app.interfaces.grpc.interceptors.logging_interceptor import GrpcLoggingInterceptor
from app.interfaces.grpc.servicer import FaceServiceServicer
from proto.face.v1 import face_pb2_grpc


class GrpcServer:
    """Quản lý lifecycle của gRPC server."""

    def __init__(self, settings: AppSettings, servicer: FaceServiceServicer) -> None:
        self._settings = settings
        self._servicer = servicer
        workers = getattr(settings, "grpc_max_workers", getattr(settings, "workers", 4))
        self._executor = ThreadPoolExecutor(max_workers=workers)
        self._interceptors = [
            GrpcLoggingInterceptor(),
            GrpcErrorInterceptor(),
        ]
        self._server = grpc.server(
            self._executor,
            interceptors=self._interceptors,
        )
        face_pb2_grpc.add_FaceServiceServicer_to_server(self._servicer, self._server)  # type: ignore[no-untyped-call]
        host = getattr(settings, "grpc_host", getattr(settings, "host", "0.0.0.0"))
        port = getattr(settings, "grpc_port", 50051)
        self._server.add_insecure_port(f"{host}:{port}")

    def start(self) -> None:
        """Khởi động gRPC server."""
        self._server.start()

    def stop(self, grace: float = 5.0) -> None:
        """Dừng gRPC server."""
        event = self._server.stop(grace)
        if event is not None:
            event.wait()

    def wait_for_termination(self, timeout: float | None = None) -> None:
        """Chờ gRPC server dừng."""
        self._server.wait_for_termination(timeout=timeout)
