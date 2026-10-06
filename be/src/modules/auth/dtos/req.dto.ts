import {
  IsEmail,
  IsNotEmpty,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class VerifyEmailReq {
  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  @IsNotEmpty()
  email!: string;

  @ApiProperty({ example: '123456' })
  @IsString()
  @IsNotEmpty()
  code!: string;
}

export class LoginReq {
  @ApiProperty({ example: 'johndoe' })
  @IsString()
  @IsNotEmpty()
  username!: string;

  @ApiProperty({ example: 'password123' })
  @IsString()
  @IsNotEmpty()
  password!: string;
}

export class RegisterReq {
  @ApiProperty({ example: 'johndoe' })
  @IsString()
  @IsNotEmpty()
  username!: string;

  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  @IsNotEmpty()
  email!: string;

  @ApiProperty({ example: 'password123', minLength: 6 })
  @IsString()
  @MinLength(6)
  password!: string;

  @ApiProperty({ example: 'John Doe', required: false })
  @IsString()
  @IsOptional()
  displayName?: string;
}

export class ForgotPasswordReq {
  @ApiProperty({ example: 'user@example.com' })
  @IsString()
  @IsNotEmpty()
  email!: string;
}

export class UpdatePasswordReq {
  @ApiProperty({ example: 'oldPassword123' })
  @IsString()
  @IsNotEmpty()
  oldPassword!: string;

  @ApiProperty({ example: 'newPassword123', minLength: 6 })
  @IsString()
  @MinLength(6)
  newPassword!: string;
}

export class RefreshTokenReq {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsString()
  @IsNotEmpty()
  refreshToken!: string;
}
