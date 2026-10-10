import { Face } from '../../domain/entities/face.entity';

export const FACE_DETECTOR_PORT = 'FACE_DETECTOR_PORT';

export interface FaceDetectorPort {
  detect(imageBuffer: Buffer): Promise<Face[]>;
}
