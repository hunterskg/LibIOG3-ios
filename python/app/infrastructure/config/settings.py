from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


class AppSettings(BaseSettings):
    """Cấu hình ứng dụng Face Service qua biến môi trường."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    host: str = "0.0.0.0"
    grpc_port: int = 50051
    workers: int = 4
    log_level: Literal["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"] = "INFO"

    face_match_threshold: float = 0.68
    similarity_threshold: float = 0.68
    liveness_threshold: float = 0.80

    min_blur_score: float = 100.0
    min_face_size: float = 80.0
    max_pitch: float = 20.0
    max_yaw: float = 20.0
    max_roll: float = 20.0

    warmup_on_startup: bool = True
    grpc_grace_period: float = 5.0

    detector_model_path: str = "models/detector.onnx"
    embedder_model_path: str = "models/embedder.onnx"
    liveness_model_path: str = "models/liveness.onnx"
    insightface_model_name: str = "buffalo_l"
    model_root_dir: str | None = None
    liveness_input_size: tuple[int, int] = (80, 80)

    def server_address(self) -> str:
        """Trả về địa chỉ gRPC server, ví dụ '0.0.0.0:50051'."""
        return f"{self.host}:{self.grpc_port}"
