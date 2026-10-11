"""Unit tests cho lifecycle và graceful shutdown trong main.py."""

import signal
from typing import Any, cast
from unittest.mock import MagicMock, patch

import pytest

from app.infrastructure.config.settings import AppSettings
from bootstrap import ApplicationContainer
from main import main, run_server, setup_logging


@pytest.fixture
def mock_container() -> ApplicationContainer:
    """Fixture tạo ApplicationContainer giả lập."""
    mock_server = MagicMock()
    mock_settings = AppSettings(
        grpc_grace_period=2.5,
        warmup_on_startup=True,
    )
    return ApplicationContainer(
        settings=mock_settings,
        servicer=MagicMock(),
        server=mock_server,
    )


def test_setup_logging() -> None:
    """Kiểm tra setup_logging cấu hình đúng mức log."""
    setup_logging("DEBUG")
    setup_logging("INFO")


def test_run_server_lifecycle_and_signals(mock_container: ApplicationContainer) -> None:
    """Kiểm tra run_server đăng ký signals, khởi động server và chờ termination."""
    mock_server = cast(MagicMock, mock_container.server)
    with (
        patch("main.bootstrap_app", return_value=mock_container) as mock_bootstrap,
        patch("main.signal.signal") as mock_signal,
    ):
        mock_server.wait_for_termination.return_value = None

        container = run_server(mock_container.settings)

        assert container == mock_container
        mock_bootstrap.assert_called_once_with(
            settings=mock_container.settings,
            warmup=True,
        )
        mock_server.start.assert_called_once()
        mock_server.wait_for_termination.assert_called_once()

        # Kiểm tra signal.signal được đăng ký cho SIGINT
        registered_signals = [call[0][0] for call in mock_signal.call_args_list]
        assert signal.SIGINT in registered_signals
        if hasattr(signal, "SIGTERM"):
            assert signal.SIGTERM in registered_signals


def test_shutdown_handler_is_idempotent(mock_container: ApplicationContainer) -> None:
    """Kiểm tra shutdown_handler chỉ gọi server.stop một lần dù nhận nhiều signal liên tiếp."""
    mock_server = cast(MagicMock, mock_container.server)
    captured_handlers: dict[int, Any] = {}

    def fake_signal(sig: int, handler: Any) -> None:
        captured_handlers[sig] = handler

    with (
        patch("main.bootstrap_app", return_value=mock_container),
        patch("main.signal.signal", side_effect=fake_signal),
    ):
        mock_server.wait_for_termination.return_value = None
        run_server(mock_container.settings)

    handler = captured_handlers.get(signal.SIGINT)
    assert handler is not None

    # Gọi lần thứ nhất: server.stop phải được gọi
    handler(signal.SIGINT, None)
    mock_server.stop.assert_called_once_with(grace=2.5)

    # Gọi lần thứ hai: idempotent, không gọi stop lại
    handler(signal.SIGINT, None)
    assert mock_server.stop.call_count == 1


def test_run_server_handles_keyboard_interrupt(mock_container: ApplicationContainer) -> None:
    """Kiểm tra run_server bắt KeyboardInterrupt và kích hoạt graceful shutdown."""
    mock_server = cast(MagicMock, mock_container.server)
    with (
        patch("main.bootstrap_app", return_value=mock_container),
        patch("main.signal.signal"),
    ):
        mock_server.wait_for_termination.side_effect = KeyboardInterrupt()

        run_server(mock_container.settings)

        mock_server.stop.assert_called_once_with(grace=2.5)


def test_main_exits_on_fatal_error() -> None:
    """Kiểm tra main() gọi sys.exit(1) khi xảy ra lỗi nghiêm trọng."""
    with (
        patch("main.run_server", side_effect=RuntimeError("Fatal startup failure")),
        patch("main.sys.exit") as mock_exit,
    ):
        main()
        mock_exit.assert_called_once_with(1)
