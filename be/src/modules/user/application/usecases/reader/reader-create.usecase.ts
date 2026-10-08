import { ReaderCreateReq } from '../../../domain/dtos/req.dto';
import { ReaderRes } from '../../../domain/dtos/res.dto';

export interface ReaderCreateUsecase {
  /* 
    Validate:
    - check if the user not exists
    - check email is not used by other user
    */
  createReader(req: ReaderCreateReq): Promise<ReaderRes>;
}
