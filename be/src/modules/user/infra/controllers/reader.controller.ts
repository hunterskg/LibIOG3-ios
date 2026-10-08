import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { ReaderService } from '../../application/services/reader.service';
import { QueryReaderReq, ReaderUpdateReq } from '../../domain/dtos/req.dto';
import { ReaderRes, UserRes } from '../../domain/dtos/res.dto';
import { Role } from '../../domain/enums/role.enum';
import { Page } from '../../../../common/dtos/page.dto';
import { JwtGuard } from '../../../auth/infra/guard/jwt.guard';
import { RoleGuard } from '../../../auth/infra/guard/role.guard';
import { Roles } from '../../../auth/infra/decorators/role.decorator';
import { CurrentUser } from '../../../auth/infra/decorators/current-user.decorator';

@ApiTags('Readers')
@ApiBearerAuth('access-token')
@UseGuards(JwtGuard, RoleGuard)
@Controller('readers')
export class ReaderController {
  constructor(private readonly readerService: ReaderService) {}

  @Patch(':id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Update reader profile (Self or Admin)' })
  @ApiResponse({
    status: 200,
    type: ReaderRes,
    description: 'Reader profile updated successfully',
  })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  @ApiResponse({ status: 404, description: 'Reader not found' })
  async updateReader(
    @Param('id') id: string,
    @Body() req: ReaderUpdateReq,
    @CurrentUser() currentUser: UserRes,
  ): Promise<ReaderRes> {
    const isSelf = currentUser.userId === id;
    const isAdmin = currentUser.role === Role.ADMIN;
    if (!isSelf && !isAdmin) {
      throw new ForbiddenException('You can only update your own profile');
    }
    return this.readerService.updateReader(id, req);
  }

  @Get(':id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Get reader by ID (Self, Staff, or Admin)' })
  @ApiResponse({
    status: 200,
    type: ReaderRes,
    description: 'Reader found',
  })
  @ApiResponse({ status: 403, description: 'Access denied' })
  @ApiResponse({ status: 404, description: 'Reader not found' })
  async getReaderById(
    @Param('id') id: string,
    @CurrentUser() currentUser: UserRes,
  ): Promise<ReaderRes> {
    const isSelf = currentUser.userId === id;
    const isStaffOrAdmin =
      currentUser.role === Role.STAFF || currentUser.role === Role.ADMIN;
    if (!isSelf && !isStaffOrAdmin) {
      throw new ForbiddenException('Access denied');
    }
    return this.readerService.getReaderById(id);
  }

  @Get()
  @Roles(Role.STAFF, Role.ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Get readers list with pagination (Staff and Admin)',
  })
  @ApiResponse({
    status: 200,
    type: Page<ReaderRes>,
    description: 'Readers list retrieved successfully',
  })
  async getReader(@Query() req: QueryReaderReq): Promise<Page<ReaderRes>> {
    return this.readerService.getReader(req);
  }
}
