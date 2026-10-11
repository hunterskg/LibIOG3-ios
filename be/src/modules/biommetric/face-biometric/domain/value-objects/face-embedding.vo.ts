const L2_EPSILON = 1e-12;

export class FaceEmbedding {
  public readonly values: readonly number[];
  public readonly dimension: number;

  constructor(values: number[] | readonly number[], dimension: number) {
    if (values.length !== dimension) {
      throw new Error(
        `Embedding values count ${values.length} does not match dimension ${dimension}`,
      );
    }
    this.values = Object.freeze([...values]);
    this.dimension = dimension;
  }

  asVector(): number[] {
    return [...this.values];
  }

  l2Normalize(): FaceEmbedding {
    const sumSquares = this.values.reduce((sum, v) => sum + v * v, 0);
    const norm = Math.sqrt(sumSquares) + L2_EPSILON;
    const normalized = this.values.map((v) => v / norm);
    return new FaceEmbedding(normalized, this.dimension);
  }

  isL2Normalized(tolerance = 1e-3): boolean {
    const sumSquares = this.values.reduce((sum, v) => sum + v * v, 0);
    const norm = Math.sqrt(sumSquares);
    return Math.abs(norm - 1.0) <= tolerance;
  }
}
