export class VectorUtils {
  /**
   * Cosine similarity giữa 2 vector trong [-1, 1].
   * Trả về 0 nếu một trong hai vector có norm = 0.
   */
  public static cosineSimilarity(
    v1: ArrayLike<number>,
    v2: ArrayLike<number>,
  ): number {
    this.assertDimensions(v1, v2);

    let dot = 0;
    let norm1Sq = 0;
    let norm2Sq = 0;

    for (let i = 0; i < v1.length; i++) {
      const a = v1[i];
      const b = v2[i];
      dot += a * b;
      norm1Sq += a * a;
      norm2Sq += b * b;
    }

    if (norm1Sq === 0 || norm2Sq === 0) return 0;
    const sim = dot / (Math.sqrt(norm1Sq) * Math.sqrt(norm2Sq));
    return Math.max(-1, Math.min(1, sim));
  }

  /**
   * Khoảng cách Euclidean: sqrt(sum((a[i] - b[i])²))
   */
  public static euclideanDistance(
    v1: ArrayLike<number>,
    v2: ArrayLike<number>,
  ): number {
    this.assertDimensions(v1, v2);

    let sumSq = 0;
    for (let i = 0; i < v1.length; i++) {
      const diff = v1[i] - v2[i];
      sumSq += diff * diff;
    }
    return Math.sqrt(sumSq);
  }

  /**
   * Vector trung bình của tập mẫu, mặc định chuẩn hóa L2 về mặt cầu đơn vị.
   */
  public static average(
    vectors: ArrayLike<number>[],
    normalize = true,
  ): number[] {
    if (!vectors.length) throw new Error('Vectors list cannot be empty');

    const dim = vectors[0].length;
    const avg = new Float64Array(dim);

    for (const v of vectors) {
      if (v.length !== dim) {
        throw new Error(`Dimension mismatch: expected ${dim}, got ${v.length}`);
      }
      for (let i = 0; i < dim; i++) avg[i] += v[i];
    }

    for (let i = 0; i < dim; i++) avg[i] /= vectors.length;

    // ponytail: bo qua outlier trimming; them DBSCAN/median khi co tap mau lon bi nhieu
    return normalize ? this.l2Normalize(avg) : Array.from(avg);
  }

  /**
   * Chuẩn hóa L2: v / ||v||
   */
  public static l2Normalize(v: ArrayLike<number>, eps = 1e-12): number[] {
    let normSq = 0;
    for (let i = 0; i < v.length; i++) normSq += v[i] * v[i];

    const norm = Math.sqrt(normSq) + eps;
    const result = new Array<number>(v.length);
    for (let i = 0; i < v.length; i++) result[i] = v[i] / norm;
    return result;
  }

  private static assertDimensions(
    v1: ArrayLike<number>,
    v2: ArrayLike<number>,
  ): void {
    if (v1.length !== v2.length) {
      throw new Error(
        `Vector dimension mismatch: ${v1.length} != ${v2.length}`,
      );
    }
  }
}
