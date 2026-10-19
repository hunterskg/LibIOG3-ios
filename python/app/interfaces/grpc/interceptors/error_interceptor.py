import logging
from collections.abc import Callable
from typing import Any

import grpc

from app.ports.face_detector import (
    FaceNotFoundException,
    FaceServiceException,
    LowFaceQualityException,
    MultipleFacesDetectedException,
)
from app.ports.face_embedder import EmbeddingMismatchException
from app.ports.liveness_detector import SpoofDetectedException

logger = logging.getLogger(__name__)

DOMAIN_EXCEPTION_STATUS_MAP: dict[type[Exception], grpc.StatusCode] = {
    FaceNotFoundException: grpc.StatusCode.NOT_FOUND,
    MultipleFacesDetectedException: grpc.StatusCode.FAILED_PRECONDITION,
    LowFaceQualityException: grpc.StatusCode.FAILED_PRECONDITION,
    SpoofDetectedException: grpc.StatusCode.PERMISSION_DENIED,
    EmbeddingMismatchException: grpc.StatusCode.INVALID_ARGUMENT,
    ValueError: grpc.StatusCode.INVALID_ARGUMENT,
    FaceServiceException: grpc.StatusCode.INTERNAL,
    Exception: grpc.StatusCode.INTERNAL,
}


def map_exception_to_grpc_status(exc: Exception) -> tuple[grpc.StatusCode, str]:
    """Ánh xạ Python Exception sang gRPC StatusCode và message chi tiết."""
    for exc_cls, status_code in DOMAIN_EXCEPTION_STATUS_MAP.items():
        if isinstance(exc, exc_cls):
            details = str(exc)
            if not details:
                details = exc_cls.__name__
            return status_code, details
    return grpc.StatusCode.INTERNAL, str(exc) or "Internal server error"


class GrpcErrorInterceptor(grpc.ServerInterceptor):  # type: ignore[misc]
    """Interceptor bắt domain exceptions và ánh xạ sang gRPC status codes."""

    def intercept_service(
        self,
        continuation: Callable[[grpc.HandlerCallDetails], Any],
        handler_call_details: grpc.HandlerCallDetails,
    ) -> Any:
        handler = continuation(handler_call_details)
        if handler is None:
            return None

        if handler.unary_unary:
            behavior = handler.unary_unary

            def wrapper(request: Any, context: grpc.ServicerContext) -> Any:
                try:
                    return behavior(request, context)
                except grpc.RpcError:
                    raise
                except Exception as exc:  # noqa: BLE001 - Interceptor bắt ngoại lệ mức cao để map sang gRPC status
                    logger.exception("gRPC method unhandled exception: %s", exc)
                    status_code, details = map_exception_to_grpc_status(exc)
                    context.abort(status_code, details)

            return grpc.unary_unary_rpc_method_handler(
                wrapper,
                request_deserializer=handler.request_deserializer,
                response_serializer=handler.response_serializer,
            )

        return handler
