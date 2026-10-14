import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcryptjs';

import { BaseService } from '../../../../common/application/service/base.service';
import { Page } from '../../../../common/dtos/page.dto';
import { User } from '../../domain/entities/user.entity';
import {
  ReaderRes,
  StaffRes,
  UserAuthRes,
  UserRes,
} from '../../domain/dtos/res.dto';
import {
  QueryReaderReq,
  QueryStaffReq,
  ReaderCreateReq,
  ReaderUpdateReq,
  StaffCreateReq,
  StaffUpdateReq,
} from '../../domain/dtos/req.dto';
import { Role } from '../../domain/enums/role.enum';
import { UserStatus } from '../../domain/enums/user-statis.enum';
import { ReaderCreateUsecase } from '../usecases/reader/reader-create.usecase';
import { ReaderUpdateUsecase } from '../usecases/reader/reader-update.usecast';
import { ViewReaderUsecase } from '../usecases/reader/view-reader.usecase';
import { StaffCreateUsecase } from '../usecases/staff/staff-create.usecase';
import { StaffUpdateUsecase } from '../usecases/staff/staff-update.usecast';
import { ViewStaffUsecase } from '../usecases/staff/view-staff.usecase';
import { AssignRoleUsecase } from '../usecases/staff/assign-role.usecase';

@Injectable()
export class UserService
  extends BaseService
  implements
    ReaderCreateUsecase,
    ReaderUpdateUsecase,
    ViewReaderUsecase,
    StaffCreateUsecase,
    StaffUpdateUsecase,
    ViewStaffUsecase,
    AssignRoleUsecase
{
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {
    super(UserService.name);
  }

  async getById(id: string): Promise<UserRes | null> {
    const user = await this.userRepo.findOne({
      where: { id },
    });

    return user ? UserRes.of(user) : null;
  }

  async getByIdForAuth(id: string): Promise<UserAuthRes | null> {
    const user = await this.userRepo.findOne({
      where: { id },
    });

    return user
      ? { ...UserRes.of(user), passwordHash: user.passwordHash }
      : null;
  }

  async isExist(id: string): Promise<boolean> {
    return this.userRepo.existsBy({ id });
  }

  /**
   * @throws {NotFoundException} Khi không tìm thấy user theo email
   */
  async getUserByEmailForAuth(email: string): Promise<UserAuthRes> {
    const user = await this.userRepo.findOne({ where: { email } });
    if (!user) {
      throw new NotFoundException(`User with email ${email} not found`);
    }
    return {
      ...UserRes.of(user),
      passwordHash: user.passwordHash,
    };
  }

  async isEmailExist(email: string): Promise<boolean> {
    const user = await this.userRepo.findOne({ where: { email } });
    return !!user;
  }

  async createUser(
    email: string,
    passwordHash: string,
    role: Role,
    fullName = '',
  ): Promise<User> {
    const newUser = this.userRepo.create({
      email,
      fullName,
      passwordHash,
      role,
      status: UserStatus.ACTIVE,
    });
    return this.userRepo.save(newUser);
  }

  /**
   * @throws {NotFoundException} Not found user with the given id
   */
  async updatePassword(userId: string, newPasswordHash: string): Promise<void> {
    const user = await this.userRepo.findOne({ where: { id: userId } });

    if (!user) {
      throw new NotFoundException(`User with id ${userId} not found`);
    }

    user.updatePassword(newPasswordHash);
    await this.userRepo.save(user);
  }

  async createReader(req: ReaderCreateReq): Promise<ReaderRes> {
    if (await this.isEmailExist(req.email)) {
      throw new ConflictException('Email already exists');
    }
    const hashedPassword = await bcrypt.hash(req.password, 10);

    const user = this.userRepo.create({
      email: req.email,
      fullName: req.fullName,
      passwordHash: hashedPassword,
      role: Role.READER,
      status: UserStatus.ACTIVE,
    });
    const savedUser = await this.userRepo.save(user);
    return ReaderRes.of(savedUser);
  }

  async getReader(req: QueryReaderReq): Promise<Page<ReaderRes>> {
    const page = Number(req.page) > 0 ? Number(req.page) : 1;
    const size = Number(req.size) > 0 ? Number(req.size) : 10;

    const qb = this.userRepo
      .createQueryBuilder('user')
      .where('user.role = :role', { role: Role.READER });

    if (req.fullName) {
      qb.andWhere('user.fullName ILIKE :fullName', {
        fullName: `%${req.fullName}%`,
      });
    }

    qb.orderBy('user.createdAt', 'DESC')
      .skip((page - 1) * size)
      .take(size);

    const [items, total] = await qb.getManyAndCount();
    return Page.of(
      items.map((u) => ReaderRes.of(u)),
      Number(total) || 0,
      { page, size },
    );
  }

  async getReaderById(id: string): Promise<ReaderRes> {
    const user = await this.userRepo.findOne({
      where: { id },
    });
    if (!user || user.role !== Role.READER) {
      throw new NotFoundException('Reader not found');
    }
    return ReaderRes.of(user);
  }

  async updateReader(id: string, req: ReaderUpdateReq): Promise<ReaderRes> {
    const user = await this.userRepo.findOne({
      where: { id, role: Role.READER },
    });
    if (!user) {
      throw new NotFoundException('Reader not found');
    }

    if (req.fullName !== undefined) {
      user.fullName = req.fullName;
    }

    const updatedUser = await this.userRepo.save(user);
    return ReaderRes.of(updatedUser);
  }

  async createStaff(req: StaffCreateReq): Promise<StaffRes> {
    if (await this.isEmailExist(req.email)) {
      throw new ConflictException('Email already exists');
    }
    const hashedPassword = await bcrypt.hash(req.password, 10);

    const user = this.userRepo.create({
      email: req.email,
      fullName: req.name,
      passwordHash: hashedPassword,
      role: (req as { role?: Role }).role ?? Role.STAFF,
      status: UserStatus.ACTIVE,
    });

    const savedUser = await this.userRepo.save(user);
    return StaffRes.of(savedUser);
  }

  async getStaff(req: QueryStaffReq): Promise<Page<StaffRes>> {
    const page = Number(req.page) > 0 ? Number(req.page) : 1;
    const size = Number(req.size) > 0 ? Number(req.size) : 10;

    const qb = this.userRepo
      .createQueryBuilder('user')
      .where('user.role IN (:...roles)', { roles: [Role.STAFF, Role.ADMIN] });

    if (req.name) {
      qb.andWhere('user.fullName ILIKE :name', { name: `%${req.name}%` });
    }
    if (req.role) {
      qb.andWhere('user.role = :role', { role: req.role });
    }

    qb.orderBy('user.createdAt', 'DESC')
      .skip((page - 1) * size)
      .take(size);

    const [items, total] = await qb.getManyAndCount();
    return Page.of(
      items.map((u) => StaffRes.of(u)),
      Number(total) || 0,
      { page, size },
    );
  }

  async getStaffById(id: string): Promise<StaffRes> {
    const user = await this.userRepo.findOne({
      where: { id },
    });
    if (!user || (user.role !== Role.STAFF && user.role !== Role.ADMIN)) {
      throw new NotFoundException('Staff not found');
    }
    return StaffRes.of(user);
  }

  async updateStaff(id: string, req: StaffUpdateReq): Promise<StaffRes> {
    const user = await this.userRepo.findOne({
      where: { id },
    });
    if (!user || (user.role !== Role.STAFF && user.role !== Role.ADMIN)) {
      throw new NotFoundException('Staff not found');
    }

    if (req.name !== undefined) {
      user.fullName = req.name;
    }

    const updatedUser = await this.userRepo.save(user);
    return StaffRes.of(updatedUser);
  }

  async assignRole(
    id: string,
    role: Role,
    currentAdminId?: string,
  ): Promise<StaffRes> {
    if (currentAdminId && id === currentAdminId) {
      throw new BadRequestException('Admin cannot assign role to himself');
    }

    const user = await this.userRepo.findOne({ where: { id } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    user.role = role;
    const savedUser = await this.userRepo.save(user);
    return StaffRes.of(savedUser);
  }
}
