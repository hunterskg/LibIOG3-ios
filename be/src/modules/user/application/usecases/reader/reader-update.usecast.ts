import { ReaderUpdateReq } from '../../../domain/dtos/req.dto';
import { ReaderRes } from '../../../domain/dtos/res.dto';

export interface ReaderUpdateUsecase {
  /*
    Validate:
    - check if the user exists
    - check if the user is a reader
    */
  updateReader(id: string, req: ReaderUpdateReq): Promise<ReaderRes>;
}
