import { Inject, Injectable } from '@nestjs/common';
import {
  FACE_DETECTOR_PORT,
  FaceDetectorPort,
} from '../ports/face-detector.port';
import { Face } from '../../domain/entities/face.entity';
import { BaseService } from '../../../../../common/application/service/base.service';

@Injectable()
export class DetectFaceService extends BaseService {
  constructor(
    @Inject(FACE_DETECTOR_PORT)
    private readonly detector: FaceDetectorPort,
  ) {
    super(DetectFaceService.name);
  }

  /**
   * @throws {Error} if imageBuffer is empty or not provided
   * @returns An array of detected faces, limited to maxFaces if specified
   */
  async execute(imageBuffer: Buffer, maxFaces = 1): Promise<Face[]> {
    if (!imageBuffer || imageBuffer.length === 0) {
      throw new Error('imageBuffer is required and cannot be empty');
    }

    const faces = await this.detector.detect(imageBuffer);
    if (maxFaces > 0) {
      return faces.slice(0, maxFaces);
    }
    return faces;
  }
}
