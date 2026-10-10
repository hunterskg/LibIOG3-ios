from app.ports.face_detector import (
    DEFAULT_MAX_BLUR,
    DEFAULT_MAX_PITCH,
    DEFAULT_MAX_ROLL,
    DEFAULT_MAX_YAW,
    DEFAULT_MIN_BLUR_SCORE,
    DEFAULT_MIN_FACE_SIZE,
    BoundingBox,
    Face,
    FaceDetectorPort,
    FaceLandmarks,
    FaceNotFoundException,
    FaceServiceException,
    LowFaceQualityException,
    MultipleFacesDetectedException,
    Point2D,
)
from app.ports.face_embedder import (
    EmbeddingMismatchException,
    FaceEmbedderPort,
    FaceEmbedding,
)
from app.ports.liveness_detector import (
    LivenessDetectorPort,
    LivenessResult,
    LivenessStatus,
    SpoofDetectedException,
)

DEFAULT_SIMILARITY_THRESHOLD: float = 0.68
DEFAULT_FACE_MATCH_THRESHOLD: float = 0.68
DEFAULT_LIVENESS_THRESHOLD: float = 0.80

__all__ = [
    "FaceDetectorPort",
    "FaceEmbedderPort",
    "LivenessDetectorPort",
    "BoundingBox",
    "Point2D",
    "FaceLandmarks",
    "Face",
    "FaceEmbedding",
    "LivenessStatus",
    "LivenessResult",
    "FaceServiceException",
    "FaceNotFoundException",
    "MultipleFacesDetectedException",
    "LowFaceQualityException",
    "SpoofDetectedException",
    "EmbeddingMismatchException",
    "DEFAULT_MAX_BLUR",
    "DEFAULT_MIN_BLUR_SCORE",
    "DEFAULT_MIN_FACE_SIZE",
    "DEFAULT_MAX_PITCH",
    "DEFAULT_MAX_YAW",
    "DEFAULT_MAX_ROLL",
    "DEFAULT_SIMILARITY_THRESHOLD",
    "DEFAULT_FACE_MATCH_THRESHOLD",
    "DEFAULT_LIVENESS_THRESHOLD",
]
