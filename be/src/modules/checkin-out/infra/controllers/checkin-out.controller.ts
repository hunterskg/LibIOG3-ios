import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { CheckInOutService } from '../../application/services/checkin-out.service';
import { CheckInOutDto } from '../dto/checkin-out.dto';
import { JwtGuard } from '../../../auth/infra/guard/jwt.guard';
import { RoleGuard } from '../../../auth/infra/guard/role.guard';
import { Roles } from '../../../auth/infra/decorators/role.decorator';
import { CurrentUser } from '../../../auth/infra/decorators/current-user.decorator';
import { Role } from '../../../user/domain/enums/role.enum';

@Controller('checkin-out')
@UseGuards(JwtGuard, RoleGuard)
export class CheckInOutController {
  constructor(private readonly checkInOutService: CheckInOutService) {}

  @Post()
  @Roles(Role.STAFF)
  async checkInOut(
    @CurrentUser('userId') staffId: string,
    @Body() dto: CheckInOutDto,
  ) {
    return this.checkInOutService.checkInOut(staffId, dto);
  }
}
