"""Unit tests cho bootstrap_app và warmup_models."""

import logging
from unittest.mock import MagicMock, patch

import pytest

from app.infrastructure.config.settings import AppSettings
from bootstrap import ApplicationContainer, bootstrap_app, warmup_models


def test_bootstrap_app_default_no_warmup() -> None:
    """Kiểm tra bootstrap_app mặc định không chạy warmup và trả về container hợp lệ."""
    with (
        patch("bootstrap.warmup_models") as mock_warmup,
        patch("bootstrap.GrpcServer") as mock_server_cls,
    ):
        mock_server = MagicMock()
        mock_server_cls.return_value = mock_server
        container = bootstrap_app(warmup=False)

        assert isinstance(container, ApplicationContainer)
        assert container.settings is not None
        assert container.detector is not None
        assert container.embedder is not None
        assert container.liveness_detector is not None
        assert container.server == mock_server
        mock_warmup.assert_not_called()


def test_bootstrap_app_triggers_warmup_when_requested() -> None:
    """Kiểm tra bootstrap_app gọi warmup_models khi warmup=True."""
    with (
        patch("bootstrap.warmup_models") as mock_warmup,
        patch("bootstrap.GrpcServer") as mock_server_cls,
    ):
        mock_server = MagicMock()
        mock_server_cls.return_value = mock_server
        container = bootstrap_app(warmup=True)

        mock_warmup.assert_called_once_with(container)
        assert container.server == mock_server


def test_warmup_models_calls_all_adapters() -> None:
    """Kiểm tra warmup_models gọi warmup() trên detector, embedder, và liveness_detector."""
    mock_detector = MagicMock()
    mock_embedder = MagicMock()
    mock_liveness = MagicMock()

    container = ApplicationContainer(
        settings=AppSettings(),
        servicer=MagicMock(),
        server=MagicMock(),
        detector=mock_detector,
        embedder=mock_embedder,
        liveness_detector=mock_liveness,
    )

    warmup_models(container)

    mock_detector.warmup.assert_called_once()
    mock_embedder.warmup.assert_called_once()
    mock_liveness.warmup.assert_called_once()


def test_warmup_models_skips_none_or_missing_warmup() -> None:
    """Kiểm tra warmup_models bỏ qua các adapter là None hoặc không có method warmup."""
    container = ApplicationContainer(
        settings=AppSettings(),
        servicer=MagicMock(),
        server=MagicMock(),
        detector=None,
        embedder=MagicMock(spec=[]),  # không có warmup
        liveness_detector=None,
    )

    # Không raise AttributeError hay Exception
    warmup_models(container)


def test_warmup_models_catches_model_load_errors(caplog: pytest.LogCaptureFixture) -> None:
    """Kiểm tra warmup_models xử lý FileNotFoundError/RuntimeError và ghi log warning."""
    mock_detector = MagicMock()
    mock_detector.warmup.side_effect = FileNotFoundError("Model file not found")
    mock_embedder = MagicMock()
    mock_embedder.warmup.side_effect = RuntimeError("CUDA out of memory")
    mock_liveness = MagicMock()

    container = ApplicationContainer(
        settings=AppSettings(),
        servicer=MagicMock(),
        server=MagicMock(),
        detector=mock_detector,
        embedder=mock_embedder,
        liveness_detector=mock_liveness,
    )

    with caplog.at_level(logging.WARNING):
        warmup_models(container)

    mock_liveness.warmup.assert_called_once()
    assert any("Warming up face detector failed" in record.message for record in caplog.records)
    assert any("Warming up face embedder failed" in record.message for record in caplog.records)
