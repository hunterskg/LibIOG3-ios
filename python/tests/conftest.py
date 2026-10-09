"""Pytest fixtures cho Face Service."""

from unittest.mock import MagicMock

import pytest


@pytest.fixture
def mock_detector():
    """Mock cho FaceDetectorPort."""
    detector = MagicMock()
    detector.detect.return_value = []
    return detector


@pytest.fixture
def mock_embedder():
    """Mock cho FaceEmbedderPort."""
    embedder = MagicMock()
    embedder.extract_embedding.return_value = MagicMock(
        values=tuple([0.0] * 512),
        dimension=512,
    )
    return embedder


@pytest.fixture
def mock_liveness_detector():
    """Mock cho LivenessDetectorPort."""
    detector = MagicMock()
    detector.check_liveness.return_value = MagicMock(
        is_live=True,
        status=MagicMock(name="REAL"),
        confidence=0.99,
        details={},
    )
    return detector


@pytest.fixture
def mock_similarity():
    """Mock cho SimilarityCalculator."""
    calculator = MagicMock()
    calculator.compute_cosine_similarity.return_value = 0.98
    calculator.compute_euclidean_distance.return_value = 0.20
    return calculator


@pytest.fixture
def mock_face():
    """Mock đối tượng Face."""
    from app.domain.entities.face import Face

    return Face(id="test-1", bbox=MagicMock())
