import { Page } from '../../../../../common/dtos/page.dto';
import { QueryStaffReq } from '../../../domain/dtos/req.dto';
import { StaffRes } from '../../../domain/dtos/res.dto';

export interface ViewStaffUsecase {
  /* 
    validate:
    - check if the user exists
    - check if the user is a staff
    */
  getStaffById(staffId: string): Promise<StaffRes>;
  getStaff(req: QueryStaffReq): Promise<Page<StaffRes>>;
}
