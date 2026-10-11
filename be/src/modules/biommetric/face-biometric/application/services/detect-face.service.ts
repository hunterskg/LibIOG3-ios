import { Inject, Injectable } from '@nestjs/common';
import {
  FACE_DETECTOR_PORT,
  FaceDetectorPort,
} from '../ports/face-detector.port';
import { Face } from '../../domain/entities/face.entity';
import { BaseService } from '../../../../../common/application/service/base.service';
import { FaceNotFoundException } from '../../domain/exceptions/face-not-found.exception';
import { MultipleFacesDetectedException } from '../../domain/exceptions/multiple-faces-detected.exception';

@Injectable()
export class DetectFaceService extends BaseService {
  constructor(
    @Inject(FACE_DETECTOR_PORT)
    private readonly detector: FaceDetectorPort,
  ) {
    super(DetectFaceService.name);
  }

  // Hiện tại không ném ngoại lệ nếu không phát hiện khuôn mặt
  /**
   * @throws {Error} if imageBuffer is empty or not provided
   * @returns An array of detected faces, limited to maxFaces if specified
   */
  async execute(imageBuffer: Buffer, maxFaces = 1): Promise<Face[]> {
    if (!imageBuffer || imageBuffer.length === 0) {
      throw new Error('imageBuffer is required and cannot be empty');
    }

    if (maxFaces < 0) {
      throw new FaceNotFoundException('Not found any face in the image');
    }

    const faces = await this.detector.detect(imageBuffer);

    if (faces.length > maxFaces) {
      throw new MultipleFacesDetectedException(
        `Detected ${faces.length} faces, but only ${maxFaces} allowed.`,
      );
    }

    if (maxFaces > 0) {
      return faces.slice(0, maxFaces);
    }
    return faces;
  }
}
