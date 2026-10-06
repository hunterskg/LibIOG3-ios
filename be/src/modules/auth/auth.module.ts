import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { PassportModule } from '@nestjs/passport';

import { User } from '../user/domain/entities/user.entity';
import { Reader } from '../user/domain/entities/reader.entity';
import { RefreshToken } from './domain/refresh-token.entity';
import { UserModule } from '../user/user.module';

import { AuthController } from './infra/controllers/auth.controller';
import { AuthService } from './application/services/auth.service';
import { RefreshTokenService } from './application/services/refresh-token.service';
import { JwtStrategy } from './infra/strategies/jwt.strategy';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, Reader, RefreshToken]),
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('JWT_SECRET', 'jwt-secret'),
        signOptions: {
          expiresIn: config.get('JWT_EXPIRES_IN', '1d'),
        },
      }),
    }),
    UserModule,
  ],
  controllers: [AuthController],
  providers: [AuthService, RefreshTokenService, JwtStrategy],
  exports: [AuthService, RefreshTokenService],
})
export class AuthModule {}
