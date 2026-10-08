jest.mock('@nestjs/typeorm', () => ({
  InjectRepository: () => () => {},
  getRepositoryToken: (entity: any) => entity,
}));

jest.mock('bcryptjs', () => ({
  hash: jest.fn().mockImplementation(async () => 'hashed_pwd'),
  compare: jest.fn().mockImplementation(async () => true),
}));

import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { DataSource, Repository } from 'typeorm';

import { ReaderService } from './reader.service';
import { Reader } from '../../domain/entities/reader.entity';
import { User } from '../../domain/entities/user.entity';
import { Role } from '../../domain/enums/role.enum';
import { UserStatus } from '../../domain/enums/user-statis.enum';
import { ReaderCreateReq, ReaderUpdateReq } from '../../domain/dtos/req.dto';

describe('ReaderService', () => {
  let service: ReaderService;
  let readerRepo: jest.Mocked<Repository<Reader>>;
  let userRepo: jest.Mocked<Repository<User>>;
  let dataSource: jest.Mocked<DataSource>;

  const mockEntityManager = {
    create: jest.fn(),
    save: jest.fn(),
  };

  beforeEach(() => {
    readerRepo = {
      findOne: jest.fn(),
      save: jest.fn(),
      createQueryBuilder: jest.fn(),
    } as unknown as jest.Mocked<Repository<Reader>>;

    userRepo = {
      findOne: jest.fn(),
    } as unknown as jest.Mocked<Repository<User>>;

    dataSource = {
      transaction: jest.fn(),
    } as unknown as jest.Mocked<DataSource>;

    service = new ReaderService(readerRepo, userRepo, dataSource);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('createReader', () => {
    const createReq: ReaderCreateReq = {
      email: 'reader@example.com',
      password: 'Password123',
      fullName: 'Nguyen Van A',
      phone: '0912345678',
      dateOfBirth: '2000-01-01',
    };

    it('should create reader and user successfully in a transaction', async () => {
      userRepo.findOne.mockResolvedValue(null);

      const createdUser = {
        id: 'uuid-1',
        email: createReq.email,
        passwordHash: 'hashed_pwd',
        role: Role.READER,
        status: UserStatus.ACTIVE,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as User;

      const createdReader = {
        id: 'uuid-1',
        fullName: createReq.fullName,
        phone: createReq.phone,
        dateOfBirth: new Date('2000-01-01'),
        registeredAt: new Date(),
        updatedAt: new Date(),
        user: createdUser,
      } as Reader;

      dataSource.transaction.mockImplementation(async (cb: any) => {
        mockEntityManager.create.mockReturnValueOnce(createdUser);
        mockEntityManager.save.mockResolvedValueOnce(createdUser);

        mockEntityManager.create.mockReturnValueOnce(createdReader);
        mockEntityManager.save.mockResolvedValueOnce(createdReader);

        return cb(mockEntityManager);
      });

      const result = await service.createReader(createReq);

      expect(userRepo.findOne).toHaveBeenCalledWith({
        where: { email: createReq.email },
      });
      expect(dataSource.transaction).toHaveBeenCalled();
      expect(result.id).toBe('uuid-1');
      expect(result.fullName).toBe(createReq.fullName);
      expect(result.user.email).toBe(createReq.email);
    });

    it('should throw ConflictException if email already exists', async () => {
      userRepo.findOne.mockResolvedValue({ id: 'uuid-existing' } as User);

      await expect(service.createReader(createReq)).rejects.toThrow(
        ConflictException,
      );
      expect(dataSource.transaction).not.toHaveBeenCalled();
    });

    it('should rollback transaction if error occurs while saving', async () => {
      userRepo.findOne.mockResolvedValue(null);

      dataSource.transaction.mockRejectedValue(new Error('DB Error'));

      await expect(service.createReader(createReq)).rejects.toThrow('DB Error');
    });
  });

  describe('updateReader', () => {
    const updateReq: ReaderUpdateReq = {
      fullName: 'Nguyen Van B',
      phone: '0987654321',
    };

    it('should update reader profile successfully with id and req arguments', async () => {
      const mockUser = {
        id: 'uuid-1',
        role: Role.READER,
      } as User;

      const mockReader = {
        id: 'uuid-1',
        fullName: 'Nguyen Van A',
        phone: '0912345678',
        user: mockUser,
      } as Reader;

      userRepo.findOne.mockResolvedValue(mockUser);
      readerRepo.findOne.mockResolvedValue(mockReader);
      readerRepo.save.mockImplementation(async (entity: any) => entity);

      const result = await service.updateReader('uuid-1', updateReq);

      expect(userRepo.findOne).toHaveBeenCalledWith({
        where: { id: 'uuid-1' },
      });
      expect(readerRepo.findOne).toHaveBeenCalledWith({
        where: { id: 'uuid-1' },
        relations: { user: true },
      });
      expect(readerRepo.save).toHaveBeenCalled();
      expect(result.fullName).toBe('Nguyen Van B');
      expect(result.phone).toBe('0987654321');
    });

    it('should throw BadRequestException if id is missing', async () => {
      await expect(service.updateReader('', updateReq)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('should throw NotFoundException if user is not found', async () => {
      userRepo.findOne.mockResolvedValue(null);

      await expect(service.updateReader('uuid-999', updateReq)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw ForbiddenException if user is not a reader', async () => {
      userRepo.findOne.mockResolvedValue({
        id: 'uuid-1',
        role: Role.STAFF,
      } as User);

      await expect(service.updateReader('uuid-1', updateReq)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('should throw NotFoundException if reader profile is not found', async () => {
      userRepo.findOne.mockResolvedValue({
        id: 'uuid-1',
        role: Role.READER,
      } as User);
      readerRepo.findOne.mockResolvedValue(null);

      await expect(service.updateReader('uuid-1', updateReq)).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('getReaderById', () => {
    it('should return reader when found', async () => {
      const mockUser = { id: 'uuid-1', role: Role.READER } as User;
      const mockReader = {
        id: 'uuid-1',
        fullName: 'Nguyen Van A',
        user: mockUser,
      } as Reader;

      readerRepo.findOne.mockResolvedValue(mockReader);

      const result = await service.getReaderById('uuid-1');

      expect(result.id).toBe('uuid-1');
      expect(result.fullName).toBe('Nguyen Van A');
    });

    it('should throw NotFoundException when reader not found', async () => {
      readerRepo.findOne.mockResolvedValue(null);

      await expect(service.getReaderById('uuid-999')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw NotFoundException when reader user has role other than READER', async () => {
      const mockStaffUser = { id: 'uuid-1', role: Role.STAFF } as User;
      const mockReader = {
        id: 'uuid-1',
        fullName: 'Not A Reader',
        user: mockStaffUser,
      } as Reader;

      readerRepo.findOne.mockResolvedValue(mockReader);

      await expect(service.getReaderById('uuid-1')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('getReader', () => {
    it('should return paginated readers with default pagination', async () => {
      const mockUser = { id: 'uuid-1', role: Role.READER } as User;
      const mockReader = {
        id: 'uuid-1',
        fullName: 'Nguyen Van A',
        phone: '0912345678',
        user: mockUser,
      } as Reader;

      const mockQb = {
        leftJoinAndSelect: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn().mockResolvedValue([[mockReader], 1]),
      };

      readerRepo.createQueryBuilder.mockReturnValue(mockQb as any);

      const result = await service.getReader({
        page: 1,
        size: 10,
        fullName: 'Van',
      });

      expect(readerRepo.createQueryBuilder).toHaveBeenCalledWith('reader');
      expect(mockQb.leftJoinAndSelect).toHaveBeenCalledWith(
        'reader.user',
        'user',
      );
      expect(mockQb.andWhere).toHaveBeenCalledWith(
        'reader.fullName ILIKE :fullName',
        { fullName: '%Van%' },
      );
      expect(result.data.length).toBe(1);
      expect(result.total).toBe(1);
      expect(result.data[0].fullName).toBe('Nguyen Van A');
    });

    it('should parse string page and size safely in getReader', async () => {
      const mockUser = { id: 'uuid-1', role: Role.READER } as User;
      const mockReader = {
        id: 'uuid-1',
        fullName: 'Nguyen Van A',
        user: mockUser,
      } as Reader;

      const mockQb = {
        leftJoinAndSelect: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn().mockResolvedValue([[mockReader], '5']),
      };

      readerRepo.createQueryBuilder.mockReturnValue(mockQb as any);

      const result = await service.getReader({
        page: '2' as any,
        size: '5' as any,
      });

      expect(mockQb.skip).toHaveBeenCalledWith(5);
      expect(mockQb.take).toHaveBeenCalledWith(5);
      expect(result.req.page).toBe(2);
      expect(result.req.size).toBe(5);
      expect(result.total).toBe(5);
    });
  });
});
