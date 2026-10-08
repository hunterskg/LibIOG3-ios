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
import { ReaderCreateUsecase } from '../usecases/reader/reader-create.usecase';
import { ReaderUpdateUsecase } from '../usecases/reader/reader-update.usecast';
import {
  QueryReaderReq,
  ReaderCreateReq,
  ReaderUpdateReq,
} from '../../domain/dtos/req.dto';
import { ReaderRes } from '../../domain/dtos/res.dto';
import { User } from '../../domain/entities/user.entity';
import { Reader } from '../../domain/entities/reader.entity';
import { Role } from '../../domain/enums/role.enum';
import { UserStatus } from '../../domain/enums/user-statis.enum';
import { ViewReaderUsecase } from '../usecases/reader/view-reader.usecase';
import { Page } from '../../../../common/dtos/page.dto';

@Injectable()
export class ReaderService
  extends BaseService
  implements ReaderCreateUsecase, ReaderUpdateUsecase, ViewReaderUsecase
{
  constructor(
    @InjectRepository(Reader)
    private readonly readerRepo: Repository<Reader>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly dataSource: DataSource,
  ) {
    super(ReaderService.name);
  }

  async getReader(req: QueryReaderReq): Promise<Page<ReaderRes>> {
    const page = Number(req.page) > 0 ? Number(req.page) : 1;
    const size = Number(req.size) > 0 ? Number(req.size) : 10;

    const qb = this.readerRepo
      .createQueryBuilder('reader')
      .leftJoinAndSelect('reader.user', 'user');

    if (req.fullName) {
      qb.andWhere('reader.fullName ILIKE :fullName', {
        fullName: `%${req.fullName}%`,
      });
    }
    if (req.phone) {
      qb.andWhere('reader.phone ILIKE :phone', { phone: `%${req.phone}%` });
    }
    if (req.dateOfBirth) {
      qb.andWhere('reader.dateOfBirth = :dateOfBirth', {
        dateOfBirth: req.dateOfBirth,
      });
    }

    qb.orderBy('reader.registeredAt', 'DESC')
      .skip((page - 1) * size)
      .take(size);

    const [items, total] = await qb.getManyAndCount();
    return Page.of(
      items.map((reader) => ReaderRes.of(reader)),
      Number(total) || 0,
      { page, size },
    );
  }

  async createReader(req: ReaderCreateReq): Promise<ReaderRes> {
    const existingUser = await this.userRepo.findOne({
      where: { email: req.email },
    });
    if (existingUser) {
      throw new ConflictException('Email already exists');
    }

    const hashedPassword = await bcrypt.hash(req.password, 10);

    const savedReader = await this.dataSource.transaction(async (manager) => {
      const user = manager.create(User, {
        email: req.email,
        passwordHash: hashedPassword,
        role: Role.READER,
        status: UserStatus.ACTIVE,
      });
      const savedUser = await manager.save(User, user);

      const reader = manager.create(Reader, {
        id: savedUser.id,
        fullName: req.fullName,
        phone: req.phone,
        dateOfBirth: req.dateOfBirth ? new Date(req.dateOfBirth) : undefined,
      });
      const persistedReader = await manager.save(Reader, reader);
      persistedReader.user = savedUser;
      return persistedReader;
    });

    return ReaderRes.of(savedReader);
  }

  async updateReader(id: string, req: ReaderUpdateReq): Promise<ReaderRes> {
    if (!id) {
      throw new BadRequestException('User ID is required to update reader');
    }

    const user = await this.userRepo.findOne({ where: { id } });
    if (!user) {
      throw new NotFoundException(`User with id ${id} not found`);
    }

    if (user.role !== Role.READER) {
      throw new ForbiddenException('User is not a reader');
    }

    const reader = await this.readerRepo.findOne({
      where: { id },
      relations: { user: true },
    });
    if (!reader) {
      throw new NotFoundException('Reader profile not found');
    }

    if (req.fullName !== undefined) {
      reader.fullName = req.fullName;
    }
    if (req.phone !== undefined) {
      reader.phone = req.phone;
    }
    if (req.dateOfBirth !== undefined) {
      reader.dateOfBirth = req.dateOfBirth
        ? new Date(req.dateOfBirth)
        : undefined;
    }

    const updatedReader = await this.readerRepo.save(reader);
    updatedReader.user = user;
    return ReaderRes.of(updatedReader);
  }

  async getReaderById(id: string): Promise<ReaderRes> {
    const reader = await this.readerRepo.findOne({
      where: { id },
      relations: { user: true },
    });
    if (!reader || !reader.user) {
      throw new NotFoundException('Reader not found');
    }
    if (reader.user.role !== Role.READER) {
      throw new NotFoundException('Reader not found');
    }
    return ReaderRes.of(reader);
  }
}
