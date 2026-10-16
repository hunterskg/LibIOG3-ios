import { IsString, Matches } from 'class-validator';

export class CheckInOutDto {
  @IsString()
  @Matches(/^[a-fA-F0-9]{64}$/, {
    message: 'QR token phải gồm 64 ký tự hex.',
  })
  token!: string;
}
