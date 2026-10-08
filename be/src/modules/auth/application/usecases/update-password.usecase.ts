import { UpdatePasswordReq } from '../../dtos/req.dto';

export interface UpdatePasswordUseCase {
  updatePassword(userId: string, req: UpdatePasswordReq): Promise<void>;
}
