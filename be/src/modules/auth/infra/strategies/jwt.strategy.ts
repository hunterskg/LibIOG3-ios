import { BadRequestException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { UserService } from '../../../user/application/services/user.service';
import { UserRes } from '../../../user/domain/dtos/res.dto';
import { JwtRes } from '../../dtos/response.dto';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(
    private readonly configService: ConfigService,
    private readonly userService: UserService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_SECRET', 'jwt-secret'),
    });
  }

  async validate(payload: JwtRes): Promise<UserRes> {
    if (!payload?.sub) {
      throw new BadRequestException(
        'Invalid token payload: missing subject (sub)',
      );
    }

    return await this.userService.getUserById(payload.sub);
  }
}
