import { RegisterFaceReq } from '../../dtos/req.dto';
import { RegisterFaceRes } from '../../dtos/res.dto';

export interface RegisterFaceUseCase {
  registerFace(
    imageBuffer: Buffer,
    req: RegisterFaceReq,
  ): Promise<RegisterFaceRes>;
}
