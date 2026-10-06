import { Injectable, UnauthorizedException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { LessThan, Repository } from 'typeorm';

import { UserService } from '../../../user/application/services/user.service';
import { BaseService } from '../../../../common/application/service/base.service';
import { RefreshToken } from '../../domain/refresh-token.entity';

@Injectable()
export class RefreshTokenService extends BaseService {
  constructor(
    @InjectRepository(RefreshToken)
    private readonly refreshTokenRepo: Repository<RefreshToken>,
    private readonly userService: UserService,
  ) {
    super(RefreshTokenService.name);
  }

  async createRefreshToken(
    userId: string,
    days: number = 7,
  ): Promise<RefreshToken> {
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + days);

    const refreshToken = RefreshToken.create(userId, expiresAt);
    return await this.refreshTokenRepo.save(refreshToken);
  }

  async getRefreshToken(token: string): Promise<RefreshToken> {
    const refreshToken = await this.refreshTokenRepo.findOne({
      where: { token },
    });

    if (!refreshToken) {
      throw new UnauthorizedException('Refresh token not found');
    }

    return refreshToken;
  }

  async validateRefreshToken(token: string): Promise<RefreshToken> {
    const refreshToken = await this.getRefreshToken(token);

    if (refreshToken.isRevoked || refreshToken.isExpired()) {
      throw new UnauthorizedException('Refresh token is invalid or expired');
    }

    return refreshToken;
  }

  async revokeRefreshToken(token: string): Promise<void> {
    const refreshToken = await this.getRefreshToken(token);
    refreshToken.revoke();
    await this.refreshTokenRepo.save(refreshToken);
  }

  async revokeRefreshTokenByUserId(userId: string): Promise<void> {
    await this.refreshTokenRepo.update(
      { userId, isRevoked: false },
      { isRevoked: true, revokedAt: new Date() },
    );
  }

  async deleteExpiredAndRevokedTokens(): Promise<void> {
    await this.refreshTokenRepo.delete({
      isRevoked: true,
      expiresAt: LessThan(new Date()),
    });
  }
}
