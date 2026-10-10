export class BoundingBox {
  constructor(
    public readonly x: number,
    public readonly y: number,
    public readonly width: number,
    public readonly height: number,
    public readonly confidence: number = 0.0,
  ) {}

  area(): number {
    return Math.max(0.0, this.width * this.height);
  }

  toXyxy(): [number, number, number, number] {
    return [this.x, this.y, this.x + this.width, this.y + this.height];
  }

  static fromXyxy(
    x1: number,
    y1: number,
    x2: number,
    y2: number,
    confidence = 0.0,
  ): BoundingBox {
    return new BoundingBox(
      x1,
      y1,
      Math.max(0.0, x2 - x1),
      Math.max(0.0, y2 - y1),
      confidence,
    );
  }
}
