import { UserRes } from '../../../user/domain/dtos/res.dto';
import { RegisterReq, VerifyEmailReq } from '../../dtos/req.dto';
import { RegisterPendingRes } from '../../dtos/response.dto';

export interface RegisterUseCase {
  register(req: RegisterReq): Promise<RegisterPendingRes>;
  verifyEmail(req: VerifyEmailReq): Promise<UserRes>;
}
