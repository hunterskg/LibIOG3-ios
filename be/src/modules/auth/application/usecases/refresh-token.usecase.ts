import { AuthRes } from '../../dtos/response.dto';

export interface RefreshTokenUseCase {
  refreshToken(token: string): Promise<AuthRes>;
}
