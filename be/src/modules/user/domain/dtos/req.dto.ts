import {
  IsDateString,
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { AtLeastNonEmpty } from '../../../../common/validators/at-least-non-empty.validator';
import { PageReq } from '../../../../common/dtos/page.dto';
import { Role } from '../enums/role.enum';

export class ReaderCreateReq {
  @ApiProperty({ example: 'exmaple@gmail.com' })
  @IsEmail({}, { message: 'Email không hợp lệ' })
  @IsNotEmpty({ message: 'Email không được để trống' })
  email!: string;

  @ApiProperty({ example: 'Password123' })
  @IsString()
  @IsNotEmpty({ message: 'Mật khẩu không được để trống' })
  @MinLength(6, { message: 'Mật khẩu phải từ 6 ký tự trở lên' })
  password!: string;

  @ApiProperty({ example: 'Nguyễn Văn A' })
  @IsString()
  @IsNotEmpty({ message: 'Họ và tên không được để trống' })
  fullName!: string;

  @ApiPropertyOptional({ example: '0912345678' })
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiPropertyOptional({ example: '2000-01-01' })
  @IsDateString({}, { message: 'Ngày sinh phải đúng định dạng YYYY-MM-DD' })
  @IsOptional()
  dateOfBirth?: string;
}

export class StaffCreateReq {
  @ApiProperty({ example: 'exmaple@gmail.com' })
  @IsEmail({}, { message: 'Email không hợp lệ' })
  @IsNotEmpty({ message: 'Email không được để trống' })
  email!: string;

  @ApiProperty({ example: 'Password123' })
  @IsString()
  @IsNotEmpty({ message: 'Mật khẩu không được để trống' })
  @MinLength(6, { message: 'Mật khẩu phải từ 6 ký tự trở lên' })
  password!: string;

  @ApiProperty({ example: 'Trần Thị B' })
  @IsString()
  @IsNotEmpty({ message: 'Tên nhân viên không được để trống' })
  name!: string;
}

@AtLeastNonEmpty(1)
export class ReaderUpdateReq {
  @ApiPropertyOptional({ example: 'Nguyễn Văn A' })
  @IsString()
  @IsOptional()
  fullName?: string;

  @ApiPropertyOptional({ example: '0912345678' })
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiPropertyOptional({ example: '2000-01-01' })
  @IsDateString({}, { message: 'Ngày sinh phải đúng định dạng YYYY-MM-DD' })
  @IsOptional()
  dateOfBirth?: string;
}

@AtLeastNonEmpty(1)
export class StaffUpdateReq {
  @ApiPropertyOptional({ example: 'Trần Thị B' })
  @IsString()
  @IsOptional()
  name?: string;
}

export class QueryReaderReq extends PageReq {
  @ApiPropertyOptional({ example: 'Nguyễn Văn A' })
  @IsString()
  @IsOptional()
  fullName?: string;

  @ApiPropertyOptional({ example: '0912345678' })
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiPropertyOptional({ example: '2000-01-01' })
  @IsDateString({}, { message: 'Ngày sinh phải đúng định dạng YYYY-MM-DD' })
  @IsOptional()
  dateOfBirth?: string;
}

export class QueryStaffReq extends PageReq {
  @ApiPropertyOptional({ example: 'Trần Thị B' })
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional({ example: 'admin' })
  @IsEnum(Role, { message: 'Role không hợp lệ' })
  @IsOptional()
  role?: Role;
}

export class AssignRoleReq {
  @ApiProperty({ enum: Role, example: Role.STAFF })
  @IsEnum(Role, { message: 'Role không hợp lệ' })
  @IsNotEmpty({ message: 'Role không được để trống' })
  role!: Role;
}
