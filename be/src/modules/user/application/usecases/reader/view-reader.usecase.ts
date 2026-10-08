import { Page } from '../../../../../common/dtos/page.dto';
import { QueryReaderReq } from '../../../domain/dtos/req.dto';
import { ReaderRes } from '../../../domain/dtos/res.dto';

export interface ViewReaderUsecase {
  /*
    validate:
    - check if the user exists
    - check if the user is a reader
    */
  getReaderById(readerId: string): Promise<ReaderRes>;

  getReader(req: QueryReaderReq): Promise<Page<ReaderRes>>;
}
