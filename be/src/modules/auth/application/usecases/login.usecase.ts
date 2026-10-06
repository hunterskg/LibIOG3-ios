import { LoginReq } from '../../dtos/req.dto';
import { AuthRes } from '../../dtos/response.dto';

export interface LoginUseCase {
  login(req: LoginReq): Promise<AuthRes>;
}
