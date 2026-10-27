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
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { GateService } from '../../application/services/gate.service';
import {
  CreateGateReq,
  GateRes,
  UpdateGateReq,
} from '../../domain/dtos/gate.dto';
import { JwtGuard } from '../../../auth/infra/guard/jwt.guard';
import { RoleGuard } from '../../../auth/infra/guard/role.guard';
import { Roles } from '../../../auth/infra/decorators/role.decorator';
import { Role } from '../../../user/domain/enums/role.enum';

@ApiTags('Gates')
@ApiBearerAuth('access-token')
@Controller('gates')
@UseGuards(JwtGuard, RoleGuard)
export class GateController {
  constructor(private readonly service: GateService) {}

  @Post()
  @Roles(Role.ADMIN)
  create(@Body() req: CreateGateReq): Promise<GateRes> {
    return this.service.create(req);
  }

  @Get()
  @Roles(Role.ADMIN, Role.STAFF)
  list(): Promise<GateRes[]> {
    return this.service.list();
  }

  @Get(':id')
  @Roles(Role.ADMIN, Role.STAFF)
  get(@Param('id') id: string): Promise<GateRes> {
    return this.service.get(id);
  }

  @Get(':id/staff')
  @Roles(Role.ADMIN)
  listStaff(@Param('id') id: string) {
    return this.service.listStaff(id);
  }

  @Patch(':id')
  @Roles(Role.ADMIN)
  update(
    @Param('id') id: string,
    @Body() req: UpdateGateReq,
  ): Promise<GateRes> {
    return this.service.update(id, req);
  }

  @Delete(':id')
  @Roles(Role.ADMIN)
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@Param('id') id: string): Promise<void> {
    return this.service.remove(id);
  }
}
