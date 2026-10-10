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

    const v1 = this.toFloat32Array(emb1.values);
    const v2 = this.toFloat32Array(emb2.values);

    let dot = 0;
    let norm1Squared = 0;
    let norm2Squared = 0;

    for (let i = 0; i < v1.length; i++) {
      const a = v1[i];
      const b = v2[i];

      dot += a * b;
      norm1Squared += a * a;
      norm2Squared += b * b;
    }

    if (norm1Squared === 0 || norm2Squared === 0) {
      return 0;
    }

    const similarity =
      dot / (Math.sqrt(norm1Squared) * Math.sqrt(norm2Squared));

    return Math.max(-1, Math.min(1, similarity));
  }

  /**
   * Euclidean distance: sqrt(sum((a[i] - b[i])²)).
   */
  public static compute_euclidean_distance(
    emb1: FaceEmbedding,
    emb2: FaceEmbedding,
  ): number {
    this.assertSameDimension(emb1, emb2);

    const v1 = this.toFloat32Array(emb1.values);
    const v2 = this.toFloat32Array(emb2.values);

    let sumSquared = 0;

    for (let i = 0; i < v1.length; i++) {
      const diff = v1[i] - v2[i];
      sumSquared += diff * diff;
    }

    return Math.sqrt(sumSquared);
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

  private static toFloat32Array(values: ArrayLike<number>): Float32Array {
    return values instanceof Float32Array ? values : Float32Array.from(values);
  }
}
