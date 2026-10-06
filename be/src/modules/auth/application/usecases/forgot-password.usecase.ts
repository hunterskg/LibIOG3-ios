import { ForgotPasswordReq } from '../../dtos/req.dto';

export interface ForgotPasswordUseCase {
  forgotPassword(req: ForgotPasswordReq): Promise<void>;
}
