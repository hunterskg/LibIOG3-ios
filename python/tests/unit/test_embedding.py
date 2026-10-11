import pytest

from app.ports.face_embedder import EmbeddingMismatchException, FaceEmbedding


def test_face_embedding_cosine_similarity():
    emb1 = FaceEmbedding(values=(1.0, 0.0, 0.0), dimension=3)
    emb2 = FaceEmbedding(values=(1.0, 0.0, 0.0), dimension=3)
    assert emb1.cosine_similarity(emb2) == pytest.approx(1.0)

    emb_opp = FaceEmbedding(values=(-1.0, 0.0, 0.0), dimension=3)
    assert emb1.cosine_similarity(emb_opp) == pytest.approx(-1.0)

    emb_orth = FaceEmbedding(values=(0.0, 1.0, 0.0), dimension=3)
    assert emb1.cosine_similarity(emb_orth) == pytest.approx(0.0)


def test_face_embedding_mismatch_dimension():
    emb1 = FaceEmbedding(values=(1.0, 0.0), dimension=2)
    emb2 = FaceEmbedding(values=(1.0, 0.0, 0.0), dimension=3)
    with pytest.raises(EmbeddingMismatchException):
        emb1.cosine_similarity(emb2)
