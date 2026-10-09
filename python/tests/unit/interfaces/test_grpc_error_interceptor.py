from unittest.mock import MagicMock

import grpc
import pytest

from app.domain.exceptions.face_exceptions import (
    EmbeddingMismatchException,
    FaceDomainException,
    FaceNotFoundException,
    LowFaceQualityException,
    MultipleFacesDetectedException,
    SpoofDetectedException,
)
from app.interfaces.grpc.interceptors.error_interceptor import (
    DOMAIN_EXCEPTION_STATUS_MAP,
    GrpcErrorInterceptor,
    map_exception_to_grpc_status,
)


def test_domain_exception_status_map_keys():
    """Kiểm tra DOMAIN_EXCEPTION_STATUS_MAP định nghĩa đầy đủ các exception mapping."""
    assert DOMAIN_EXCEPTION_STATUS_MAP[FaceNotFoundException] == grpc.StatusCode.NOT_FOUND
    assert (
        DOMAIN_EXCEPTION_STATUS_MAP[MultipleFacesDetectedException]
        == grpc.StatusCode.FAILED_PRECONDITION
    )
    assert (
        DOMAIN_EXCEPTION_STATUS_MAP[LowFaceQualityException] == grpc.StatusCode.FAILED_PRECONDITION
    )
    assert DOMAIN_EXCEPTION_STATUS_MAP[SpoofDetectedException] == grpc.StatusCode.PERMISSION_DENIED
    assert (
        DOMAIN_EXCEPTION_STATUS_MAP[EmbeddingMismatchException] == grpc.StatusCode.INVALID_ARGUMENT
    )
    assert DOMAIN_EXCEPTION_STATUS_MAP[ValueError] == grpc.StatusCode.INVALID_ARGUMENT
    assert DOMAIN_EXCEPTION_STATUS_MAP[FaceDomainException] == grpc.StatusCode.INTERNAL
    assert DOMAIN_EXCEPTION_STATUS_MAP[Exception] == grpc.StatusCode.INTERNAL


@pytest.mark.parametrize(
    ("exc", "expected_status", "expected_detail"),
    [
        (FaceNotFoundException("No face found"), grpc.StatusCode.NOT_FOUND, "No face found"),
        (
            MultipleFacesDetectedException("2 faces found"),
            grpc.StatusCode.FAILED_PRECONDITION,
            "2 faces found",
        ),
        (
            LowFaceQualityException("Blurry image"),
            grpc.StatusCode.FAILED_PRECONDITION,
            "Blurry image",
        ),
        (
            SpoofDetectedException("Spoofing attempt"),
            grpc.StatusCode.PERMISSION_DENIED,
            "Spoofing attempt",
        ),
        (
            EmbeddingMismatchException("Dims do not match"),
            grpc.StatusCode.INVALID_ARGUMENT,
            "Dims do not match",
        ),
        (
            ValueError("image_bytes is required"),
            grpc.StatusCode.INVALID_ARGUMENT,
            "image_bytes is required",
        ),
        (FaceDomainException("Domain error"), grpc.StatusCode.INTERNAL, "Domain error"),
        (RuntimeError("Unexpected error"), grpc.StatusCode.INTERNAL, "Unexpected error"),
    ],
)
def test_map_exception_to_grpc_status(
    exc: Exception,
    expected_status: grpc.StatusCode,
    expected_detail: str,
) -> None:
    status, detail = map_exception_to_grpc_status(exc)
    assert status == expected_status
    assert detail == expected_detail


def test_map_exception_empty_details_fallback():
    exc = FaceNotFoundException("")
    status, detail = map_exception_to_grpc_status(exc)
    assert status == grpc.StatusCode.NOT_FOUND
    assert detail == "FaceNotFoundException"


def test_interceptor_returns_none_if_continuation_returns_none():
    interceptor = GrpcErrorInterceptor()
    continuation = MagicMock(return_value=None)
    details = MagicMock()

    result = interceptor.intercept_service(continuation, details)
    assert result is None


def test_interceptor_passes_through_non_unary_unary_handler():
    interceptor = GrpcErrorInterceptor()
    mock_handler = MagicMock()
    mock_handler.unary_unary = None
    continuation = MagicMock(return_value=mock_handler)
    details = MagicMock()

    result = interceptor.intercept_service(continuation, details)
    assert result == mock_handler


def test_interceptor_wrapper_success():
    interceptor = GrpcErrorInterceptor()
    mock_behavior = MagicMock(return_value="success_response")
    mock_handler = MagicMock()
    mock_handler.unary_unary = mock_behavior
    mock_handler.request_deserializer = MagicMock()
    mock_handler.response_serializer = MagicMock()

    continuation = MagicMock(return_value=mock_handler)
    details = MagicMock()

    wrapped_handler = interceptor.intercept_service(continuation, details)
    assert wrapped_handler is not None

    mock_request = MagicMock()
    mock_context = MagicMock()
    response = wrapped_handler.unary_unary(mock_request, mock_context)

    assert response == "success_response"
    mock_behavior.assert_called_once_with(mock_request, mock_context)
    mock_context.abort.assert_not_called()


def test_interceptor_wrapper_catches_domain_exception_and_aborts():
    interceptor = GrpcErrorInterceptor()
    mock_behavior = MagicMock(side_effect=FaceNotFoundException("No face"))
    mock_handler = MagicMock()
    mock_handler.unary_unary = mock_behavior
    mock_handler.request_deserializer = MagicMock()
    mock_handler.response_serializer = MagicMock()

    continuation = MagicMock(return_value=mock_handler)
    details = MagicMock()

    wrapped_handler = interceptor.intercept_service(continuation, details)

    mock_request = MagicMock()
    mock_context = MagicMock()
    wrapped_handler.unary_unary(mock_request, mock_context)

    mock_context.abort.assert_called_once_with(grpc.StatusCode.NOT_FOUND, "No face")


def test_interceptor_wrapper_reraises_rpc_error():
    interceptor = GrpcErrorInterceptor()
    rpc_error = grpc.RpcError("Already aborted")
    mock_behavior = MagicMock(side_effect=rpc_error)
    mock_handler = MagicMock()
    mock_handler.unary_unary = mock_behavior
    mock_handler.request_deserializer = MagicMock()
    mock_handler.response_serializer = MagicMock()

    continuation = MagicMock(return_value=mock_handler)
    details = MagicMock()

    wrapped_handler = interceptor.intercept_service(continuation, details)

    mock_request = MagicMock()
    mock_context = MagicMock()
    with pytest.raises(grpc.RpcError):
        wrapped_handler.unary_unary(mock_request, mock_context)

    mock_context.abort.assert_not_called()
