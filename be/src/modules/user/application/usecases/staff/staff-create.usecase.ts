import { StaffCreateReq } from '../../../domain/dtos/req.dto';
import { StaffRes } from '../../../domain/dtos/res.dto';

export interface StaffCreateUsecase {
  /* 
    Validate:
    - check if the user not exists
    - check email is not used by other user
    */
  createStaff(req: StaffCreateReq): Promise<StaffRes>;
}
