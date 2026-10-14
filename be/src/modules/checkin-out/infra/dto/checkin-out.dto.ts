import { IsIn, IsString, Matches } from 'class-validator';

export class CheckInOutDto {
  @IsString()
  @Matches(/^[a-f0-9]{64}$/i)
  token!: string;

  @IsIn(['CHECK_IN', 'CHECK_OUT'])
  action!: 'CHECK_IN' | 'CHECK_OUT';
}
