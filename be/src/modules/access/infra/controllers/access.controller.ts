import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtGuard } from '../../../auth/infra/guard/jwt.guard';
import { RoleGuard } from '../../../auth/infra/guard/role.guard';
import { Roles } from '../../../auth/infra/decorators/role.decorator';
import { CurrentUser } from '../../../auth/infra/decorators/current-user.decorator';
import { Role } from '../../../user/domain/enums/role.enum';
import { AccessService } from '../../application/services/access.service';
import {
  QueryAccessLogsDto,
  ReportSummaryQueryDto,
  TriggerClosureDto,
} from '../dto/access-query.dto';

@ApiTags('Access & Reports')
@ApiBearerAuth('access-token')
@UseGuards(JwtGuard, RoleGuard)
@Controller('access')
export class AccessController {
  constructor(private readonly accessService: AccessService) {}

  @Get('logs')
  @Roles(Role.ADMIN, Role.STAFF)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Lấy lịch sử ra/vào thư viện có phân trang và bộ lọc',
  })
  getLogs(@Query() query: QueryAccessLogsDto) {
    return this.accessService.getAccessLogs(query);
  }

  @Get('active-readers')
  @Roles(Role.ADMIN, Role.STAFF)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Danh sách bạn đọc hiện đang ở TRONG thư viện',
  })
  getActiveReaders() {
    return this.accessService.getActiveReaders();
  }

  @Post('closures/trigger')
  @Roles(Role.ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Đóng cửa thư viện & Tự động check-out (AUTO_CHECK_OUT) toàn bộ bạn đọc còn trong thư viện (Admin)',
  })
  triggerClosure(
    @CurrentUser('userId') adminId: string,
    @Body() dto: TriggerClosureDto,
  ) {
    return this.accessService.triggerClosure(adminId, dto);
  }

  @Get('reports/summary')
  @Roles(Role.ADMIN, Role.STAFF)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Báo cáo thống kê tổng hợp lượt ra/vào, phương thức và khung giờ',
  })
  getReportSummary(@Query() query: ReportSummaryQueryDto) {
    return this.accessService.getReportSummary(query);
  }
}
