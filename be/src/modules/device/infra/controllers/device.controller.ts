import {
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { DeviceService } from '../../application/services/device.service';
import {
  ActivateDeviceReq,
  AssignDeviceReq,
  QueryAssignmentReq,
} from '../../domain/dtos/req.dto';
import {
  ActivateDeviceRes,
  AssignDeviceRes,
  DeviceAssignmentRes,
} from '../../domain/dtos/res.dto';
import { CurrentUser } from '../../../auth/infra/decorators/current-user.decorator';
import { Roles } from '../../../auth/infra/decorators/role.decorator';
import { JwtGuard } from '../../../auth/infra/guard/jwt.guard';
import { RoleGuard } from '../../../auth/infra/guard/role.guard';
import { Role } from '../../../user/domain/enums/role.enum';
import { UserRes } from '../../../user/domain/dtos/res.dto';

@ApiTags('Devices')
@Controller('devices')
export class DeviceController {
  constructor(private readonly deviceService: DeviceService) {}

  @Post('assign')
  @UseGuards(JwtGuard, RoleGuard)
  @Roles(Role.ADMIN)
  @ApiBearerAuth('access-token')
  @ApiOperation({
    summary: 'Assign a device activation code to staff (Admin only)',
  })
  @ApiResponse({ status: 201, type: AssignDeviceRes })
  @HttpCode(HttpStatus.CREATED)
  assign(
    @Body() req: AssignDeviceReq,
    @CurrentUser('userId') adminId: string,
  ): Promise<AssignDeviceRes> {
    return this.deviceService.assign(req, adminId);
  }

  @Post('activate')
  @ApiOperation({ summary: 'Activate a device with an activation code' })
  @ApiResponse({ status: 200, type: ActivateDeviceRes })
  activate(@Body() req: ActivateDeviceReq): Promise<ActivateDeviceRes> {
    return this.deviceService.activate(req);
  }

  @Delete('assignments/:id')
  @UseGuards(JwtGuard, RoleGuard)
  @Roles(Role.ADMIN)
  @ApiBearerAuth('access-token')
  @ApiOperation({ summary: 'Revoke a device assignment (Admin only)' })
  @HttpCode(HttpStatus.NO_CONTENT)
  async revoke(@Param('id') id: string): Promise<void> {
    await this.deviceService.revoke(id);
  }

  @Get('assignments')
  @UseGuards(JwtGuard, RoleGuard)
  @Roles(Role.ADMIN)
  @ApiBearerAuth('access-token')
  @ApiOperation({ summary: 'List device assignments (Admin only)' })
  list(@Query() req: QueryAssignmentReq): Promise<DeviceAssignmentRes[]> {
    return this.deviceService.list(req);
  }

  @Get('assignments/staff/:staffId')
  @UseGuards(JwtGuard, RoleGuard)
  @Roles(Role.ADMIN, Role.STAFF)
  @ApiBearerAuth('access-token')
  @ApiOperation({ summary: 'List assignments for a staff account' })
  async listForStaff(
    @Param('staffId') staffId: string,
    @CurrentUser() currentUser: UserRes,
  ): Promise<DeviceAssignmentRes[]> {
    if (currentUser.userId !== staffId && currentUser.role !== Role.ADMIN) {
      throw new ForbiddenException(
        'You can only view your own device assignments',
      );
    }
    return this.deviceService.listForStaff(staffId);
  }
}
