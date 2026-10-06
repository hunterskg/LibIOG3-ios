import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';

import { BaseService } from '../../../../common/application/service/base.service';
import { User } from '../../../user/domain/entities/user.entity';
import { Reader } from '../../../user/domain/entities/reader.entity';
import { Role } from '../../../user/domain/enums/role.enum';

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
import { UserRes } from '../../../user/domain/dtos/res.dto';
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
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(Reader)
    private readonly readerRepo: Repository<Reader>,
    private readonly refreshTokenService: RefreshTokenService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    @Inject(INTERNAL_EVENT_BUS)
    private readonly internalEventBus: InternalEventBus,
    @Inject(CACHE_SERVICE)
    private readonly cacheService: CacheService,
  ) {
    super(AuthService.name);
  }

  async login(req: LoginReq): Promise<AuthRes> {
    const user = await this.userRepo.findOne({
      where: { email: req.username },
    });

    if (!user || !user.passwordHash || !user.isActived()) {
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

    const user = await this.userRepo.findOne({
      where: { id: Number(storedToken.userId) },
    });

    if (!user || !user.isActived()) {
      throw new UnauthorizedException('User account is inactive or not found');
    }

    // Token rotation: revoke used token
    await this.refreshTokenService.revokeRefreshToken(token);

    return this.generateAuthRes(user);
  }

  async updatePassword(userId: string, req: UpdatePasswordReq): Promise<void> {
    const user = await this.userRepo.findOne({
      where: { id: Number(userId) },
    });
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
    user.updatePassword(hashedPassword);
    await this.userRepo.save(user);

    // Revoke all existing refresh tokens for this user
    await this.refreshTokenService.revokeRefreshTokenByUserId(userId);
  }

  async register(req: RegisterReq): Promise<RegisterPendingRes> {
    const existing = await this.userRepo.findOne({
      where: { email: req.email },
    });

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

    const hashedPassword = await bcrypt.hash(req.password, 10);

    const code = Math.floor(100000 + Math.random() * 900000).toString();

    const ttl = Number(
      this.configService.get<number>('EMAIL_VERIFICATION_TTL', 900),
    );

    const displayName = req.displayName?.trim() || req.email;

    const cacheKey = `auth:verify:${req.email}`;
    await this.cacheService.set(
      cacheKey,
      {
        email: req.email,
        password: hashedPassword,
        displayName,
        code,
      },
      ttl,
    );

    await this.internalEventBus.publish(
      new UserRegisteredEvent(req.email, displayName, code, ttl),
    );

    return {
      message: 'Verification code sent to email',
      email: req.email,
    };
  }

  async verifyEmail(req: VerifyEmailReq): Promise<UserRes> {
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

    const existing = await this.userRepo.findOne({
      where: { email: cachedData.email },
    });
    if (existing) {
      await this.cacheService.del(cacheKey);
      throw new ConflictException('Email already exists');
    }

    const user = User.create(
      cachedData.email,
      cachedData.password,
      Role.READER,
    );
    const savedUser = await this.userRepo.save(user);

    const reader = this.readerRepo.create({
      id: savedUser.id,
      fullName: cachedData.displayName || cachedData.email,
    });
    await this.readerRepo.save(reader);

    await this.cacheService.del(cacheKey);

    await this.internalEventBus.publish(
      new UserCreatedEvent(
        savedUser.id.toString(),
        savedUser.email,
        cachedData.displayName || savedUser.email,
        cachedData.displayName || savedUser.email,
      ),
    );

    return UserRes.of(savedUser);
  }

  async forgotPassword(req: ForgotPasswordReq): Promise<void> {
    // ponytail: implement email sending via MAIL_SERVICE when forgot password flow is designed
    this.logger.log(`Forgot password requested for email: ${req.email}`);
    await Promise.resolve();
  }

  private async generateAuthRes(user: User): Promise<AuthRes> {
    const payload: JwtRes = {
      sub: user.id.toString(),
      role: user.role,
    };

    const accessToken = await this.jwtService.signAsync(payload);

    const refreshTokenDays = Number(
      this.configService.get<number>('REFRESH_TOKEN_DAYS', 7),
    );

    const refreshToken = await this.refreshTokenService.createRefreshToken(
      user.id.toString(),
      refreshTokenDays,
    );

    return {
      accessToken,
      refreshToken: refreshToken.token,
      user: UserRes.of(user),
    };
  }
}
