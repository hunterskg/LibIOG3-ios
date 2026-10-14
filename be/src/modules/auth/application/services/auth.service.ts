import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';

import { BaseService } from '../../../../common/application/service/base.service';

import { LoginUseCase } from '../usecases/login.usecase';
import { RefreshTokenUseCase } from '../usecases/refresh-token.usecase';
import { UpdatePasswordUseCase } from '../usecases/update-password.usecase';
import { RegisterUseCase } from '../usecases/register.usecase';
import { ForgotPasswordUseCase } from '../usecases/forgot-password.usecase';
import { RefreshTokenService } from './refresh-token.service';
import {
  CACHE_SERVICE,
  CacheService,
} from '../../../infra/cache/application/interface/cache-service.interface';
import { UserRegisteredEvent } from '../../domain/events/user-registered.event';
import { UserCreatedEvent } from '../../../user/domain/events/user-created.event';
import {
  ReaderRes,
  UserAuthRes,
  UserRes,
} from '../../../user/domain/dtos/res.dto';
import { AuthRes, JwtRes, RegisterPendingRes } from '../../dtos/response.dto';
import {
  ForgotPasswordReq,
  LoginReq,
  RegisterReq,
  UpdatePasswordReq,
  VerifyEmailReq,
} from '../../dtos/req.dto';
import {
  INTERNAL_EVENT_BUS,
  InternalEventBus,
} from '../../../infra/event/application/internal-event-bus.interface';
import { UserService } from '../../../user/application/services/user.service';
import { codeExpirationTime } from '../../domain/constant';

@Injectable()
export class AuthService
  extends BaseService
  implements
    LoginUseCase,
    RefreshTokenUseCase,
    UpdatePasswordUseCase,
    RegisterUseCase,
    ForgotPasswordUseCase
{
  constructor(
    private readonly refreshTokenService: RefreshTokenService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    @Inject(INTERNAL_EVENT_BUS)
    private readonly internalEventBus: InternalEventBus,
    @Inject(CACHE_SERVICE)
    private readonly cacheService: CacheService,
    private readonly userService: UserService,
  ) {
    super(AuthService.name);
  }

  /**
   * @throws {NotFoundException} if the verification code has expired or is invalid
   */
  async resendCode(email: string): Promise<void> {
    const cacheKey = `auth:verify:${email}`;
    const cachedData = await this.cacheService.get<{
      email: string;
      password: string;
      displayName: string;
      code: string;
    }>(cacheKey);

    if (!cachedData) {
      throw new NotFoundException(
        'Verification code has expired or is invalid',
      );
    }

    const code = Math.floor(100000 + Math.random() * 900000).toString();

    const ttl = codeExpirationTime;
    await this.cacheService.set(cacheKey, { ...cachedData, code }, ttl);

    this.internalEventBus
      .publish(
        new UserRegisteredEvent(
          cachedData.email,
          cachedData.displayName,
          code,
          ttl,
        ),
      )
      .catch((err) => {
        this.logger.error(
          `Failed to publish UserRegisteredEvent for email ${cachedData.email}: ${err}`,
        );
      });
  }

  /**
   * @throws {NotFoundException} if the user with the given email is not found
   * @throws {UnauthorizedException} if the email or password is invalid
   *
   */
  async login(req: LoginReq): Promise<AuthRes> {
    this.logger.log(`Login attempt for email: ${req.email} ${req.password}`);

    const user = await this.userService.getUserByEmailForAuth(req.email);

    if (!user.passwordHash || !user.isActive) {
      throw new UnauthorizedException('Invalid username or password');
    }

    const isPasswordValid = await bcrypt.compare(
      req.password,
      user.passwordHash,
    );
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid username or password');
    }

    return this.generateAuthRes(user);
  }

  async refreshToken(token: string): Promise<AuthRes> {
    if (!token) {
      throw new UnauthorizedException('Refresh token is required');
    }

    const storedToken =
      await this.refreshTokenService.validateRefreshToken(token);

    const user = await this.userService.getById(storedToken.userId);

    if (!user || !user.isActive) {
      throw new UnauthorizedException('User account is inactive or not found');
    }

    // Token rotation: revoke used token
    await this.refreshTokenService.revokeRefreshToken(token);

    return this.generateAuthRes(user);
  }

  async updatePassword(userId: string, req: UpdatePasswordReq): Promise<void> {
    const user = await this.userService.getByIdForAuth(userId);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.passwordHash) {
      const isOldPasswordValid = await bcrypt.compare(
        req.oldPassword,
        user.passwordHash,
      );
      if (!isOldPasswordValid) {
        throw new BadRequestException('Old password is incorrect');
      }
    }

    const hashedPassword = await bcrypt.hash(req.newPassword, 10);

    await this.userService.updatePassword(userId, hashedPassword);

    // Revoke all existing refresh tokens for this user
    await this.refreshTokenService.revokeRefreshTokenByUserId(userId);
  }

  async register(req: RegisterReq): Promise<RegisterPendingRes> {
    const existing = await this.userService.isEmailExist(req.email);

    if (existing) {
      throw new ConflictException('Email already exists');
    }

    const existingPending = await this.cacheService.get(
      `auth:verify:${req.email}`,
    );

    if (existingPending) {
      throw new ConflictException(
        'A verification code has already been sent to this email. Please check your email or wait for the code to expire.',
      );
    }

    const code = Math.floor(100000 + Math.random() * 900000).toString();

    const ttl = codeExpirationTime;

    const displayName = req.displayName?.trim() || req.email;

    const cacheKey = `auth:verify:${req.email}`;

    await this.cacheService.set(
      cacheKey,
      {
        email: req.email,
        password: req.password,
        displayName,
        code,
      },
      ttl,
    );

    this.internalEventBus
      .publish(new UserRegisteredEvent(req.email, displayName, code, ttl))
      .then(() => {
        this.logger.log(
          `UserRegisteredEvent published for email ${req.email} with code ${code}`,
        );
      })
      .catch((err) => {
        this.logger.error(
          `Failed to publish UserRegisteredEvent for email ${req.email}: ${err}`,
        );
      });

    return {
      message: 'Verification code sent to email',
      email: req.email,
    };
  }

  async verifyEmail(req: VerifyEmailReq): Promise<ReaderRes> {
    const cacheKey = `auth:verify:${req.email}`;
    const cachedData = await this.cacheService.get<{
      email: string;
      password: string;
      displayName: string;
      code: string;
    }>(cacheKey);

    if (!cachedData) {
      throw new BadRequestException(
        'Verification code has expired or is invalid',
      );
    }

    if (cachedData.code !== req.code) {
      throw new BadRequestException('Invalid verification code');
    }

    const existing = await this.userService.isEmailExist(req.email);
    if (existing) {
      await this.cacheService.del(cacheKey);
      throw new ConflictException('Email already exists');
    }

    const reader = await this.userService.createReader({
      email: cachedData.email,
      password: cachedData.password,
      fullName: cachedData.displayName || cachedData.email,
    });

    await this.cacheService.del(cacheKey);

    await this.internalEventBus.publish(
      new UserCreatedEvent(
        reader.user.userId,
        reader.user.email,
        cachedData.displayName || reader.user.email,
        cachedData.displayName || reader.user.email,
      ),
    );

    return reader;
  }

  async forgotPassword(req: ForgotPasswordReq): Promise<void> {
    // ponytail: implement email sending via MAIL_SERVICE when forgot password flow is designed
    this.logger.log(`Forgot password requested for email: ${req.email}`);
    await Promise.resolve();
  }

  private async generateAuthRes(user: UserRes | UserAuthRes): Promise<AuthRes> {
    const payload: JwtRes = {
      sub: user.userId,
      role: user.role,
    };

    const accessToken = await this.jwtService.signAsync(payload);

    const refreshTokenDays = Number(
      this.configService.get<number>('REFRESH_TOKEN_DAYS', 7),
    );

    const refreshToken = await this.refreshTokenService.createRefreshToken(
      user.userId,
      refreshTokenDays,
    );

    return {
      accessToken,
      refreshToken: refreshToken.token,
      user: UserRes.of(user),
    };
  }
}
