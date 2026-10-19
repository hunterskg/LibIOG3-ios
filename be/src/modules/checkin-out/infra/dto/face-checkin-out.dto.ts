
import { IsNotEmpty, IsString } from 'class-validator';

export class FaceCheckInOutDto {
  @IsString()
  @IsNotEmpty()
  imageBase64!: string;
}
