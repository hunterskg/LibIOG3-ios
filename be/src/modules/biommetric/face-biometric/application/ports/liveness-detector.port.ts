import { LivenessResult } from '../../domain/entities/liveness-result.entity';

export const LIVENESS_DETECTOR_PORT = 'LIVENESS_DETECTOR_PORT';

export interface LivenessDetectorPort {
  checkLiveness(imageBuffer: Buffer): Promise<LivenessResult>;
}
