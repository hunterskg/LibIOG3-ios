import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
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
import { UserService } from '../../application/services/user.service';
import {
  AssignRoleReq,
  QueryStaffReq,
  StaffCreateReq,
  StaffUpdateReq,
} from '../../domain/dtos/req.dto';
import { StaffRes, UserRes } from '../../domain/dtos/res.dto';
import { Role } from '../../domain/enums/role.enum';
import { Page } from '../../../../common/dtos/page.dto';
import { JwtGuard } from '../../../auth/infra/guard/jwt.guard';
import { RoleGuard } from '../../../auth/infra/guard/role.guard';
import { Roles } from '../../../auth/infra/decorators/role.decorator';
import { CurrentUser } from '../../../auth/infra/decorators/current-user.decorator';

@ApiTags('Staffs')
@ApiBearerAuth('access-token')
@UseGuards(JwtGuard, RoleGuard)
@Controller('staffs')
export class StaffController {
  constructor(private readonly userService: UserService) {}

  @Post()
  @Roles(Role.ADMIN)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create staff with user (Admin only)' })
  @ApiResponse({
    status: 201,
    type: StaffRes,
    description: 'Staff created successfully',
  })
  @ApiResponse({ status: 409, description: 'Email already exists' })
  async createStaff(@Body() req: StaffCreateReq): Promise<StaffRes> {
    return this.userService.createStaff(req);
  }

  @Patch(':id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Update staff profile (Self or Admin)' })
  @ApiResponse({
    status: 200,
    type: StaffRes,
    description: 'Staff profile updated successfully',
  })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  @ApiResponse({ status: 404, description: 'Staff not found' })
  async updateStaff(
    @Param('id') id: string,
    @Body() req: StaffUpdateReq,
    @CurrentUser() currentUser: UserRes,
  ): Promise<StaffRes> {
    const isSelf = currentUser.userId === id;
    const isAdmin = currentUser.role === Role.ADMIN;
    if (!isSelf && !isAdmin) {
      throw new ForbiddenException('You can only update your own profile');
    }
    return this.userService.updateStaff(id, req);
  }

  @Patch(':id/role')
  @Roles(Role.ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Assign role to staff (Admin only)' })
  @ApiResponse({ status: 200, description: 'Role assigned successfully' })
  @ApiResponse({ status: 400, description: 'Invalid role assignment' })
  @ApiResponse({ status: 404, description: 'Staff not found' })
  async assignRole(
    @Param('id') id: string,
    @Body() req: AssignRoleReq,
    @CurrentUser() currentUser: UserRes,
  ): Promise<{ message: string }> {
    await this.userService.assignRole(id, req.role, currentUser.userId);
    return { message: 'Role assigned successfully' };
  }

  @Get(':id')
  @Roles(Role.STAFF, Role.ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Get staff by ID (Staff and Admin)' })
  @ApiResponse({
    status: 200,
    type: StaffRes,
    description: 'Staff found',
  })
  @ApiResponse({ status: 404, description: 'Staff not found' })
  async getStaffById(@Param('id') id: string): Promise<StaffRes> {
    return this.userService.getStaffById(id);
  }

  @Get()
  @Roles(Role.STAFF, Role.ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Get staffs list with pagination (Staff and Admin)',
  })
  @ApiResponse({
    status: 200,
    type: Page<StaffRes>,
    description: 'Staffs list retrieved successfully',
  })
  async getStaff(@Query() req: QueryStaffReq): Promise<Page<StaffRes>> {
    return this.userService.getStaff(req);
  }
}
