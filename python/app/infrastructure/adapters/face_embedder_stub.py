from app.application.ports.face_embedder import FaceEmbedderPort
from app.domain.value_objects.bounding_box import BoundingBox
from app.domain.value_objects.embedding import FaceEmbedding


class StubFaceEmbedder(FaceEmbedderPort):
    """Adapter stub cho FaceEmbedderPort (không logic chi tiết)."""

    def __init__(self, model_path: str = "models/embedder.onnx", embedding_dim: int = 512) -> None:
        self._model_path = model_path
        self._embedding_dim = embedding_dim

    def extract_embedding(
        self,
        image_bytes: bytes,
        bbox: BoundingBox | None = None,
        landmarks: object = None,
    ) -> FaceEmbedding:
        raise NotImplementedError
