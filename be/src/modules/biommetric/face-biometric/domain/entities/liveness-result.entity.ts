import { LivenessStatus } from '../enums/liveness-status.enum';

export class LivenessResult {
  public id!: string;
  public status!: LivenessStatus;
  public confidence!: number;
  public details!: Record<string, unknown> | null;

  static create(
    id: string,
    status: LivenessStatus,
    confidence = 0.0,
    details: Record<string, unknown> | null = null,
  ): LivenessResult {
    const result = new LivenessResult();
    result.id = id;
    result.status = status;
    result.confidence = confidence;
    result.details = details;
    return result;
  }

  isSpoof(): boolean {
    return this.status === LivenessStatus.SPOOF;
  }

  isLive(): boolean {
    return this.status === LivenessStatus.REAL;
  }
}
