jest.mock('@nestjs/typeorm', () => ({
  InjectRepository: () => () => {},
  getRepositoryToken: (entity: any) => entity,
}));

jest.mock('@nestjs/jwt', () => ({
  JwtService: jest.fn().mockImplementation(() => ({
    signAsync: jest.fn(),
  })),
}));

jest.mock('@nestjs/config', () => ({
  ConfigService: jest.fn().mockImplementation(() => ({
    get: jest.fn(),
  })),
}));

import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { RefreshTokenService } from './refresh-token.service';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { InternalEventBus } from '../../../infra/event/application/internal-event-bus.interface';
import { CacheService } from '../../../infra/cache/application/interface/cache-service.interface';
import { UserService } from '../../../user/application/services/user.service';
import { Role } from '../../../user/domain/enums/role.enum';
import { UserStatus } from '../../../user/domain/enums/user-statis.enum';
import { ReaderRes } from '../../../user/domain/dtos/res.dto';
import { codeExpirationTime } from '../../domain/constant';

describe('AuthService', () => {
  let authService: AuthService;
  let refreshTokenService: jest.Mocked<RefreshTokenService>;
  let jwtService: jest.Mocked<JwtService>;
  let configService: jest.Mocked<ConfigService>;
  let internalEventBus: jest.Mocked<InternalEventBus>;
  let cacheService: jest.Mocked<CacheService>;
  let userService: jest.Mocked<UserService>;

  beforeEach(() => {
    refreshTokenService = {
      validateRefreshToken: jest.fn(),
      revokeRefreshToken: jest.fn(),
      revokeRefreshTokenByUserId: jest.fn(),
      createRefreshToken: jest.fn(),
    } as unknown as jest.Mocked<RefreshTokenService>;

    jwtService = {
      signAsync: jest.fn(),
    } as unknown as jest.Mocked<JwtService>;

    configService = {
      get: jest
        .fn()
        .mockImplementation((key: string, defaultValue: any) => defaultValue),
    } as unknown as jest.Mocked<ConfigService>;

    internalEventBus = {
      publish: jest.fn().mockResolvedValue(undefined),
    };

    cacheService = {
      get: jest.fn(),
      set: jest.fn().mockResolvedValue(undefined),
      del: jest.fn().mockResolvedValue(undefined),
    } as unknown as jest.Mocked<CacheService>;

    userService = {
      isEmailExist: jest.fn(),
      getUserByEmailForAuth: jest.fn(),
      getById: jest.fn(),
      getByIdForAuth: jest.fn(),
      updatePassword: jest.fn(),
      createReader: jest.fn(),
    } as unknown as jest.Mocked<UserService>;

    authService = new AuthService(
      refreshTokenService,
      jwtService,
      configService,
      internalEventBus,
      cacheService,
      userService,
    );
  });

  describe('register', () => {
    const registerReq = {
      username: 'reader1',
      email: 'reader@example.com',
      password: 'plainPassword123',
      displayName: 'Reader One',
    };

    it('should cache raw password and publish UserRegisteredEvent', async () => {
      userService.isEmailExist.mockResolvedValue(false);
      cacheService.get.mockResolvedValue(null);

      const res = await authService.register(registerReq);

      expect(userService.isEmailExist).toHaveBeenCalledWith(registerReq.email);
      expect(cacheService.set).toHaveBeenCalledWith(
        `auth:verify:${registerReq.email}`,
        expect.objectContaining({
          email: registerReq.email,
          password: registerReq.password,
          displayName: registerReq.displayName,
        }),
        codeExpirationTime,
      );
      expect(internalEventBus.publish).toHaveBeenCalled();
      expect(res.email).toBe(registerReq.email);
    });

    it('should throw ConflictException if email exists', async () => {
      userService.isEmailExist.mockResolvedValue(true);

      await expect(authService.register(registerReq)).rejects.toThrow(
        ConflictException,
      );
    });

    it('should throw ConflictException if verification already pending', async () => {
      userService.isEmailExist.mockResolvedValue(false);
      cacheService.get.mockResolvedValue({ code: '123456' });

      await expect(authService.register(registerReq)).rejects.toThrow(
        ConflictException,
      );
    });
  });

  describe('verifyEmail', () => {
    const verifyReq = {
      email: 'reader@example.com',
      code: '123456',
    };

    const cachedData = {
      email: 'reader@example.com',
      password: 'plainPassword123',
      displayName: 'Reader One',
      code: '123456',
    };

    it('should verify email and call userService.createReader to register reader', async () => {
      cacheService.get.mockResolvedValue(cachedData);
      userService.isEmailExist.mockResolvedValue(false);

      const mockReaderRes: ReaderRes = {
        id: 'reader-uuid',
        fullName: 'Reader One',
        registeredAt: new Date(),
        updatedAt: new Date(),
        user: {
          userId: 'user-uuid',
          email: verifyReq.email,
          role: Role.READER,
          status: UserStatus.ACTIVE,
          isActive: true,
        },
      };

      userService.createReader.mockResolvedValue(mockReaderRes);

      const res = await authService.verifyEmail(verifyReq);

      expect(userService.createReader).toHaveBeenCalledWith({
        email: cachedData.email,
        password: cachedData.password,
        fullName: cachedData.displayName,
      });
      expect(cacheService.del).toHaveBeenCalledWith(
        `auth:verify:${verifyReq.email}`,
      );
      expect(internalEventBus.publish).toHaveBeenCalled();
      expect(res.id).toBe('reader-uuid');
      expect(res.user.userId).toBe('user-uuid');
      expect(res).toEqual(mockReaderRes);
    });

    it('should throw BadRequestException if code is expired or not found', async () => {
      cacheService.get.mockResolvedValue(null);

      await expect(authService.verifyEmail(verifyReq)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('should throw BadRequestException if code is invalid', async () => {
      cacheService.get.mockResolvedValue({ ...cachedData, code: '654321' });

      await expect(authService.verifyEmail(verifyReq)).rejects.toThrow(
        BadRequestException,
      );
    });
  });

  describe('resendCode', () => {
    const email = 'reader@example.com';
    const cachedData = {
      email,
      password: 'plainPassword123',
      displayName: 'Reader One',
      code: '123456',
    };

    it('should throw NotFoundException if cache miss', async () => {
      cacheService.get.mockResolvedValue(null);

      await expect(authService.resendCode(email)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should update cache with new code and publish UserRegisteredEvent on cache hit', async () => {
      cacheService.get.mockResolvedValue(cachedData);

      await authService.resendCode(email);

      expect(cacheService.get).toHaveBeenCalledWith(`auth:verify:${email}`);
      expect(cacheService.set).toHaveBeenCalledWith(
        `auth:verify:${email}`,
        expect.objectContaining({
          email: cachedData.email,
          password: cachedData.password,
          displayName: cachedData.displayName,
          code: expect.stringMatching(/^\d{6}$/),
        }),
        codeExpirationTime,
      );
      expect(internalEventBus.publish).toHaveBeenCalledWith(
        expect.objectContaining({
          email: cachedData.email,
          displayName: cachedData.displayName,
          code: expect.stringMatching(/^\d{6}$/),
          expiresInSeconds: codeExpirationTime,
        }),
      );
    });
  });
});
