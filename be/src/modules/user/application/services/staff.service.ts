import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, Repository } from 'typeorm';
import * as bcrypt from 'bcryptjs';

import { BaseService } from '../../../../common/application/service/base.service';
import { StaffCreateUsecase } from '../usecases/staff/staff-create.usecase';
import { StaffUpdateUsecase } from '../usecases/staff/staff-update.usecast';
import {
  QueryStaffReq,
  StaffCreateReq,
  StaffUpdateReq,
} from '../../domain/dtos/req.dto';
import { StaffRes } from '../../domain/dtos/res.dto';
import { User } from '../../domain/entities/user.entity';
import { Staff } from '../../domain/entities/staff.entity';
import { Role } from '../../domain/enums/role.enum';
import { UserStatus } from '../../domain/enums/user-statis.enum';
import { ViewStaffUsecase } from '../usecases/staff/view-staff.usecase';
import { AssignRoleUsecase } from '../usecases/staff/assign-role.usecase';
import { Page } from '../../../../common/dtos/page.dto';

@Injectable()
export class StaffService
  extends BaseService
  implements
    StaffCreateUsecase,
    StaffUpdateUsecase,
    ViewStaffUsecase,
    AssignRoleUsecase
{
  constructor(
    @InjectRepository(Staff)
    private readonly staffRepo: Repository<Staff>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly dataSource: DataSource,
  ) {
    super(StaffService.name);
  }

  async getStaff(req: QueryStaffReq): Promise<Page<StaffRes>> {
    const page = Number(req.page) > 0 ? Number(req.page) : 1;
    const size = Number(req.size) > 0 ? Number(req.size) : 10;

    const qb = this.staffRepo
      .createQueryBuilder('staff')
      .leftJoinAndSelect('staff.user', 'user');

    if (req.name) {
      qb.andWhere('staff.name ILIKE :name', { name: `%${req.name}%` });
    }
    if (req.role) {
      qb.andWhere('user.role = :role', { role: req.role });
    }

    qb.orderBy('staff.createdAt', 'DESC')
      .skip((page - 1) * size)
      .take(size);

    const [items, total] = await qb.getManyAndCount();
    return Page.of(
      items.map((staff) => StaffRes.of(staff)),
      Number(total) || 0,
      { page, size },
    );
  }

  async createStaff(req: StaffCreateReq): Promise<StaffRes> {
    const existingUser = await this.userRepo.findOne({
      where: { email: req.email },
    });
    if (existingUser) {
      throw new ConflictException('Email already exists');
    }

    const hashedPassword = await bcrypt.hash(req.password, 10);

    const savedStaff = await this.dataSource.transaction(async (manager) => {
      const user = manager.create(User, {
        email: req.email,
        passwordHash: hashedPassword,
        role: Role.STAFF,
        status: UserStatus.ACTIVE,
      });
      const savedUser = await manager.save(User, user);

      const staff = manager.create(Staff, {
        id: savedUser.id,
        name: req.name,
      });
      const persistedStaff = await manager.save(Staff, staff);
      persistedStaff.user = savedUser;
      return persistedStaff;
    });

    return StaffRes.of(savedStaff);
  }

  async updateStaff(id: string, req: StaffUpdateReq): Promise<StaffRes> {
    if (!id) {
      throw new BadRequestException('User ID is required to update staff');
    }

    const user = await this.userRepo.findOne({ where: { id } });
    if (!user) {
      throw new NotFoundException(`User with id ${id} not found`);
    }

    if (user.role !== Role.STAFF && user.role !== Role.ADMIN) {
      throw new ForbiddenException('User is not a staff member');
    }

    const staff = await this.staffRepo.findOne({
      where: { id },
      relations: { user: true },
    });
    if (!staff) {
      throw new NotFoundException('Staff profile not found');
    }

    if (req.name !== undefined) {
      staff.name = req.name;
    }

    const updatedStaff = await this.staffRepo.save(staff);
    updatedStaff.user = user;
    return StaffRes.of(updatedStaff);
  }

  async getStaffById(id: string): Promise<StaffRes> {
    const staff = await this.staffRepo.findOne({
      where: { id },
      relations: { user: true },
    });
    if (!staff || !staff.user) {
      throw new NotFoundException('Staff not found');
    }

    if (staff.user.role !== Role.STAFF && staff.user.role !== Role.ADMIN) {
      throw new NotFoundException('Staff not found');
    }

    return StaffRes.of(staff);
  }

  async assignRole(
    staffId: string,
    role: Role,
    currentAdminId: string,
  ): Promise<void> {
    if (staffId === currentAdminId) {
      throw new BadRequestException('Admin cannot assign role to himself');
    }

    if (role !== Role.STAFF && role !== Role.ADMIN) {
      throw new BadRequestException('Invalid role for staff');
    }

    const staff = await this.staffRepo.findOne({
      where: { id: staffId },
      relations: { user: true },
    });
    if (!staff || !staff.user) {
      throw new NotFoundException('Staff not found');
    }

    const targetUser = staff.user;
    if (targetUser.role !== Role.STAFF && targetUser.role !== Role.ADMIN) {
      throw new BadRequestException('Target user is not a staff member');
    }

    if (targetUser.role === role) {
      return;
    }

    if (targetUser.role === Role.ADMIN && role !== Role.ADMIN) {
      const activeAdminCount = await this.userRepo.count({
        where: {
          role: Role.ADMIN,
          status: UserStatus.ACTIVE,
        },
      });

      if (activeAdminCount <= 1) {
        throw new BadRequestException(
          'System must have at least one active admin',
        );
      }
    }

    targetUser.role = role;
    await this.userRepo.save(targetUser);
  }
}
