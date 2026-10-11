import { IsString, Matches } from 'class-validator';

export class VerifyQrTokenDto {
  @IsString()
  @Matches(/^[a-f0-9]{64}$/i)
  token!: string;
}