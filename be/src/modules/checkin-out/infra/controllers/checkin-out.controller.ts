import {
  BadRequestException,
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { CheckInOutService } from '../../application/services/checkin-out.service';
import { CheckInOutDto } from '../dto/checkin-out.dto';
import { FaceCheckInOutDto } from '../dto/face-checkin-out.dto';
import { CurrentUser } from '../../../auth/infra/decorators/current-user.decorator';
import { Roles } from '../../../auth/infra/decorators/role.decorator';
import { JwtGuard } from '../../../auth/infra/guard/jwt.guard';
import { RoleGuard } from '../../../auth/infra/guard/role.guard';
import { Role } from '../../../user/domain/enums/role.enum';
import { FaceDomainExceptionInterceptor } from '../../../biommetric/face-biometric/infra/interceptors/face-domain-exception.interceptor';

@Controller('checkin-out')
@UseGuards(JwtGuard, RoleGuard)
@Roles(Role.STAFF)
export class CheckInOutController {
  constructor(private readonly checkInOutService: CheckInOutService) {}

  @Post()
  @HttpCode(HttpStatus.OK)
  async checkInOut(
    @CurrentUser('userId') staffId: string,
    @Body() dto: CheckInOutDto,
  ) {
    return this.checkInOutService.checkInOut(staffId, dto);
  }

  @Post('face')
  @UseInterceptors(FaceDomainExceptionInterceptor)
  @HttpCode(HttpStatus.OK)
  async checkInOutByFace(
    @CurrentUser('userId') staffId: string,
    @Body() dto: FaceCheckInOutDto,
  ) {
    const imageBase64 = dto.imageBase64.replace(
      /^data:image\/[a-zA-Z0-9.+-]+;base64,/,
      '',
    );

    if (
      !imageBase64 ||
      !/^[A-Za-z0-9+/]*={0,2}$/.test(imageBase64) ||
      imageBase64.length % 4 === 1
    ) {
      throw new BadRequestException('Dữ liệu ảnh Base64 không hợp lệ.');
    }

    const imageBuffer = Buffer.from(imageBase64, 'base64');

    if (!imageBuffer.length) {
      throw new BadRequestException('Ảnh khuôn mặt không hợp lệ.');
    }

    return this.checkInOutService.checkInOutByFace(staffId, imageBuffer);
  }
}
