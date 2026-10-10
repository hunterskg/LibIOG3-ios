export class Point2D {
  constructor(
    public readonly x: number,
    public readonly y: number,
    public readonly index: number = 0,
  ) {}
}

export class FaceLandmarks {
  public readonly points: readonly Point2D[];

  constructor(points: Point2D[] | readonly Point2D[]) {
    this.points = Object.freeze([...points]);
  }

  count(): number {
    return this.points.length;
  }
}
