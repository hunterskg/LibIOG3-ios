import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';
import { AccessAction } from '../../../access/domain/enums/access-action.enum';

export class ManualCheckInOutDto {
  @IsUUID('4', { message: 'readerId phải là UUID hợp lệ.' })
  readerId!: string;

  @IsString({ message: 'Lý do phải là chuỗi ký tự.' })
  @IsNotEmpty({ message: 'Vui lòng nhập lý do duyệt ra/vào thủ công.' })
  @MaxLength(255, { message: 'Lý do không được vượt quá 255 ký tự.' })
  reason!: string;

  @IsOptional()
  @IsEnum(AccessAction, {
    message: 'Hành động không hợp lệ (CHECK_IN hoặc CHECK_OUT).',
  })
  action?: AccessAction;
}
