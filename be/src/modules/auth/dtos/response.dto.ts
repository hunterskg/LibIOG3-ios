import { ApiProperty } from '@nestjs/swagger';
import { Role } from '../../user/domain/enums/role.enum';
import { UserRes } from '../../user/domain/dtos/res.dto';

export class RegisterPendingRes {
  @ApiProperty({ example: 'Verification code sent to email' })
  message!: string;

  @ApiProperty({ example: 'user@example.com' })
  email!: string;
}

export class JwtRes {
  sub!: string;
  role!: Role;
}

export class TokenRes {
  accessToken!: string;
  refreshToken!: string;
}

export class AuthRes extends TokenRes {
  user!: UserRes;
}
