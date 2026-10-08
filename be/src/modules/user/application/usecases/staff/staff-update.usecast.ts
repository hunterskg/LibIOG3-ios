import { StaffUpdateReq } from '../../../domain/dtos/req.dto';
import { StaffRes } from '../../../domain/dtos/res.dto';

export interface StaffUpdateUsecase {
  /* 
    Validate:
    - check if the user exists
    - check if the user is a staff
    */
  updateStaff(id: string, req: StaffUpdateReq): Promise<StaffRes>;
}
