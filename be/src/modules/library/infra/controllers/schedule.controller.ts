import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { JwtGuard } from '../../../auth/infra/guard/jwt.guard';
import { RoleGuard } from '../../../auth/infra/guard/role.guard';
import { Roles } from '../../../auth/infra/decorators/role.decorator';
import { Role } from '../../../user/domain/enums/role.enum';
import { ScheduleService } from '../../application/services/schedule.service';
import {
  CreateScheduleDto,
  SetWeeklyDto,
  UpdateScheduleDto,
} from '../dto/schedule.dto';

@ApiTags('Library Schedules')
@Controller('library/schedules')
export class ScheduleController {
  constructor(private readonly scheduleService: ScheduleService) {}

  // Public: luồng check-in hỏi "thời điểm này thư viện có mở không?".
  // ?at=ISO8601 (bỏ trống = thời điểm hiện tại).
  @Get('status')
  @HttpCode(HttpStatus.OK)
  getStatus(@Query('at') at?: string) {
    const when = at ? new Date(at) : new Date();
    return this.scheduleService.getStatusAt(when);
  }

  @Get()
  @ApiBearerAuth('access-token')
  @UseGuards(JwtGuard, RoleGuard)
  @Roles(Role.ADMIN, Role.STAFF)
  findAll() {
    return this.scheduleService.findAll();
  }

  @Get('weekly')
  @ApiBearerAuth('access-token')
  @UseGuards(JwtGuard, RoleGuard)
  @Roles(Role.ADMIN, Role.STAFF)
  findWeekly() {
    return this.scheduleService.findWeekly();
  }

  @Get('special')
  @ApiBearerAuth('access-token')
  @UseGuards(JwtGuard, RoleGuard)
  @Roles(Role.ADMIN, Role.STAFF)
  findSpecial() {
    return this.scheduleService.findSpecial();
  }

  // Ghi đè toàn bộ lịch hàng tuần (lưới 7 ngày) trong một lần.
  @Put('weekly')
  @ApiBearerAuth('access-token')
  @UseGuards(JwtGuard, RoleGuard)
  @Roles(Role.ADMIN)
  setWeekly(@Body() dto: SetWeeklyDto) {
    return this.scheduleService.setWeekly(dto.days);
  }

  @Post()
  @ApiBearerAuth('access-token')
  @UseGuards(JwtGuard, RoleGuard)
  @Roles(Role.ADMIN)
  @HttpCode(HttpStatus.CREATED)
  create(@Body() dto: CreateScheduleDto) {
    return this.scheduleService.create(dto);
  }

  @Patch(':id')
  @ApiBearerAuth('access-token')
  @UseGuards(JwtGuard, RoleGuard)
  @Roles(Role.ADMIN)
  update(@Param('id') id: string, @Body() dto: UpdateScheduleDto) {
    return this.scheduleService.update(id, dto);
  }

  @Delete(':id')
  @ApiBearerAuth('access-token')
  @UseGuards(JwtGuard, RoleGuard)
  @Roles(Role.ADMIN)
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@Param('id') id: string) {
    return this.scheduleService.remove(id);
  }
}
