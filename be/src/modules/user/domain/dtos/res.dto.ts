import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Role } from '../enums/role.enum';
import { UserStatus } from '../enums/user-statis.enum';
import { User } from '../entities/user.entity';

export class UserRes {
  @ApiProperty({ example: '1' })
  userId!: string;

  @ApiProperty({ example: 'user@example.com' })
  email!: string;

  @ApiPropertyOptional({ example: 'Nguyễn Văn A' })
  fullName?: string;

  @ApiProperty({ enum: Role, example: Role.READER })
  role!: Role;

  @ApiPropertyOptional({ enum: UserStatus, example: UserStatus.ACTIVE })
  status?: UserStatus;

  @ApiPropertyOptional({ example: '2026-10-08T00:00:00.000Z' })
  createdAt?: Date;

  @ApiPropertyOptional({ example: '2026-10-08T00:00:00.000Z' })
  updatedAt?: Date;

  @ApiPropertyOptional({ example: true })
  isActive!: boolean;

  static of(user: User | UserRes | UserAuthRes): UserRes {
    const res = new UserRes();
    const id = (user as User).id ?? (user as UserRes).userId;
    res.userId = id.toString();
    res.email = user.email;
    res.fullName = (user as User).fullName ?? (user as any).fullName;
    res.role = user.role;
    res.status = (user as User).status ?? (user as UserRes).status;
    res.createdAt = (user as User).createdAt ?? (user as UserRes).createdAt;
    res.updatedAt = (user as User).updatedAt ?? (user as UserRes).updatedAt;
    res.isActive =
      typeof (user as User).isActived === 'function'
        ? (user as User).isActived()
        : ((user as UserRes).isActive ??
          (user as User).status === UserStatus.ACTIVE);
    return res;
  }
}

export class ReaderRes {
  @ApiProperty({ example: '1' })
  id!: string;

  @ApiProperty({ example: 'Nguyễn Văn A' })
  fullName!: string;

  @ApiPropertyOptional({ example: '0912345678' })
  phone?: string;

  @ApiPropertyOptional({ example: '2000-01-01' })
  dateOfBirth?: Date;

  @ApiPropertyOptional({ example: '2026-10-08T00:00:00.000Z' })
  registeredAt?: Date;

  @ApiPropertyOptional({ example: '2026-10-08T00:00:00.000Z' })
  updatedAt?: Date;

  @ApiPropertyOptional({ type: () => UserRes })
  user!: UserRes;

  static of(user: User): ReaderRes {
    const res = new ReaderRes();
    res.id = user.id.toString();
    res.fullName = user.fullName;
    res.registeredAt = user.createdAt;
    res.updatedAt = user.updatedAt;
    res.user = UserRes.of(user);
    return res;
  }
}

export class StaffRes {
  @ApiProperty({ example: '1' })
  id!: string;

  @ApiProperty({ example: 'Trần Thị B' })
  name!: string;

  @ApiPropertyOptional({ example: '2026-10-08T00:00:00.000Z' })
  createdAt?: Date;

  @ApiPropertyOptional({ type: () => UserRes })
  user!: UserRes;

  static of(user: User): StaffRes {
    const res = new StaffRes();
    res.id = user.id.toString();
    res.name = user.fullName;
    res.createdAt = user.createdAt;
    res.user = UserRes.of(user);
    return res;
  }
}

export class UserAuthRes extends UserRes {
  passwordHash!: string;
}
