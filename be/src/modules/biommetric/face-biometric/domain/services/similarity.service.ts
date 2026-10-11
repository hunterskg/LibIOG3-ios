import { VectorUtils } from '../../../../../common/utils/vector.utils';
import { EmbeddingMismatchException } from '../exceptions/embedding-mismatch.exception';
import { FaceEmbedding } from '../value-objects/face-embedding.vo';

export class SimilarityCalculator {
  /**
   * Cosine similarity nằm trong [-1, 1].
   * Nếu một trong hai vector có norm bằng 0, trả về 0.
   */
  public static compute_cosine_similarity(
    emb1: FaceEmbedding,
    emb2: FaceEmbedding,
  ): number {
    this.assertSameDimension(emb1, emb2);
    return VectorUtils.cosineSimilarity(emb1.values, emb2.values);
  }

  /**
   * Euclidean distance: sqrt(sum((a[i] - b[i])²)).
   */
  public static compute_euclidean_distance(
    emb1: FaceEmbedding,
    emb2: FaceEmbedding,
  ): number {
    this.assertSameDimension(emb1, emb2);
    return VectorUtils.euclideanDistance(emb1.values, emb2.values);
  }

  /**
   * Vector trung bình của nhiều FaceEmbedding, tự động chuẩn hóa L2.
   */
  public static compute_average(
    embeddings: FaceEmbedding[],
    normalize = true,
  ): FaceEmbedding {
    if (!embeddings.length) {
      throw new EmbeddingMismatchException(
        'Danh sách embeddings không được để trống',
      );
    }
    const dim = embeddings[0].dimension;
    for (const emb of embeddings) {
      if (emb.dimension !== dim) {
        throw new EmbeddingMismatchException(
          `Kích thước embedding không khớp: ${emb.dimension} != ${dim}`,
        );
      }
    }
    const avgVector = VectorUtils.average(
      embeddings.map((e) => e.values),
      normalize,
    );
    return new FaceEmbedding(avgVector, dim);
  }

  private static assertSameDimension(
    emb1: FaceEmbedding,
    emb2: FaceEmbedding,
  ): void {
    if (
      emb1.dimension !== emb2.dimension ||
      emb1.values.length !== emb2.values.length
    ) {
      throw new EmbeddingMismatchException(
        `Kích thước embedding không khớp: ` +
          `${emb1.values.length} != ${emb2.values.length}`,
      );
    }
  }
}
