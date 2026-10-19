import logging
import time
from collections.abc import Callable
from typing import Any

import grpc

default_logger = logging.getLogger(__name__)


class GrpcLoggingInterceptor(grpc.ServerInterceptor):  # type: ignore[misc]
    """Interceptor ghi log request execution time và status cho gRPC server."""

    def __init__(self, logger: logging.Logger | None = None) -> None:
        self._logger = logger or default_logger

    def intercept_service(
        self,
        continuation: Callable[[grpc.HandlerCallDetails], Any],
        handler_call_details: grpc.HandlerCallDetails,
    ) -> Any:
        handler = continuation(handler_call_details)
        if handler is None:
            return None

        method = getattr(handler_call_details, "method", "unknown_method")

        if handler.unary_unary:
            behavior = handler.unary_unary

            def wrapper(request: Any, context: grpc.ServicerContext) -> Any:
                start_time = time.perf_counter()
                self._logger.info("gRPC call started: %s", method)
                try:
                    response = behavior(request, context)
                    elapsed_ms = (time.perf_counter() - start_time) * 1000.0
                    self._logger.info(
                        "gRPC call completed: %s in %.2fms",
                        method,
                        elapsed_ms,
                    )
                    return response
                except Exception as exc:
                    elapsed_ms = (time.perf_counter() - start_time) * 1000.0
                    err_msg = str(exc) or type(exc).__name__
                    self._logger.error(
                        "gRPC call failed: %s after %.2fms - error: %s",
                        method,
                        elapsed_ms,
                        err_msg,
                    )
                    raise

            return grpc.unary_unary_rpc_method_handler(
                wrapper,
                request_deserializer=handler.request_deserializer,
                response_serializer=handler.response_serializer,
            )

        return handler
