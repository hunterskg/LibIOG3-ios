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

import { StaffService } from './staff.service';
import { Staff } from '../../domain/entities/staff.entity';
import { User } from '../../domain/entities/user.entity';
import { Role } from '../../domain/enums/role.enum';
import { UserStatus } from '../../domain/enums/user-statis.enum';
import { StaffCreateReq, StaffUpdateReq } from '../../domain/dtos/req.dto';

describe('StaffService', () => {
  let service: StaffService;
  let staffRepo: jest.Mocked<Repository<Staff>>;
  let userRepo: jest.Mocked<Repository<User>>;
  let dataSource: jest.Mocked<DataSource>;

  const mockEntityManager = {
    create: jest.fn(),
    save: jest.fn(),
  };

  beforeEach(() => {
    staffRepo = {
      findOne: jest.fn(),
      save: jest.fn(),
    } as unknown as jest.Mocked<Repository<Staff>>;

    userRepo = {
      findOne: jest.fn(),
    } as unknown as jest.Mocked<Repository<User>>;

    dataSource = {
      transaction: jest.fn(),
    } as unknown as jest.Mocked<DataSource>;

    service = new StaffService(staffRepo, userRepo, dataSource);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('createStaff', () => {
    const createReq: StaffCreateReq = {
      email: 'staff@example.com',
      password: 'Password123',
      name: 'Tran Thi B',
    };

    it('should create staff and user successfully in a transaction', async () => {
      userRepo.findOne.mockResolvedValue(null);

      const createdUser = {
        id: 'uuid-1',
        email: createReq.email,
        passwordHash: 'hashed_pwd',
        role: Role.STAFF,
        status: UserStatus.ACTIVE,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as User;

      const createdStaff = {
        id: 'uuid-1',
        name: createReq.name,
        createdAt: new Date(),
        user: createdUser,
      };

      dataSource.transaction.mockImplementation(async (cb: any) => {
        mockEntityManager.create.mockReturnValueOnce(createdUser);
        mockEntityManager.save.mockResolvedValueOnce(createdUser);

        mockEntityManager.create.mockReturnValueOnce(createdStaff);
        mockEntityManager.save.mockResolvedValueOnce(createdStaff);

        return cb(mockEntityManager);
      });

      const result = await service.createStaff(createReq);

      expect(userRepo.findOne).toHaveBeenCalledWith({
        where: { email: createReq.email },
      });
      expect(dataSource.transaction).toHaveBeenCalled();
      expect(result.id).toBe('uuid-1');
      expect(result.name).toBe(createReq.name);
      expect(result.user.email).toBe(createReq.email);
    });

    it('should throw ConflictException if email already exists', async () => {
      userRepo.findOne.mockResolvedValue({ id: 'uuid-existing' } as User);

      await expect(service.createStaff(createReq)).rejects.toThrow(
        ConflictException,
      );
      expect(dataSource.transaction).not.toHaveBeenCalled();
    });

    it('should rollback transaction if error occurs while saving', async () => {
      userRepo.findOne.mockResolvedValue(null);

      dataSource.transaction.mockRejectedValue(new Error('DB Error'));

      await expect(service.createStaff(createReq)).rejects.toThrow('DB Error');
    });
  });

  describe('updateStaff', () => {
    const updateReq: StaffUpdateReq = {
      name: 'Tran Van C',
    };

    it('should update staff profile successfully with id and req arguments', async () => {
      const mockUser = {
        id: 'uuid-1',
        role: Role.STAFF,
      } as User;

      const mockStaff = {
        id: 'uuid-1',
        name: 'Tran Thi B',
        user: mockUser,
      } as Staff;

      userRepo.findOne.mockResolvedValue(mockUser);
      staffRepo.findOne.mockResolvedValue(mockStaff);
      staffRepo.save.mockImplementation(async (entity: any) => entity);

      const result = await service.updateStaff('uuid-1', updateReq);

      expect(userRepo.findOne).toHaveBeenCalledWith({
        where: { id: 'uuid-1' },
      });
      expect(staffRepo.findOne).toHaveBeenCalledWith({
        where: { id: 'uuid-1' },
        relations: { user: true },
      });
      expect(staffRepo.save).toHaveBeenCalled();
      expect(result.name).toBe('Tran Van C');
    });

    it('should allow admin user to update any staff profile', async () => {
      const mockUser = { id: 'uuid-admin', role: Role.ADMIN } as User;
      const mockStaff = {
        id: 'uuid-admin',
        name: 'Admin Staff',
        user: mockUser,
      } as Staff;

      userRepo.findOne.mockResolvedValue(mockUser);
      staffRepo.findOne.mockResolvedValue(mockStaff);
      staffRepo.save.mockImplementation(async (entity: any) => entity);

      const result = await service.updateStaff('uuid-admin', {
        name: 'Updated Admin',
      });

      expect(result.name).toBe('Updated Admin');
    });

    it('should throw BadRequestException if id is missing', async () => {
      await expect(service.updateStaff('', updateReq)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('should throw NotFoundException if user is not found', async () => {
      userRepo.findOne.mockResolvedValue(null);

      await expect(service.updateStaff('uuid-999', updateReq)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw ForbiddenException if user is a reader', async () => {
      userRepo.findOne.mockResolvedValue({
        id: 'uuid-1',
        role: Role.READER,
      } as User);

      await expect(service.updateStaff('uuid-1', updateReq)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('should throw NotFoundException if staff profile is not found', async () => {
      userRepo.findOne.mockResolvedValue({
        id: 'uuid-1',
        role: Role.STAFF,
      } as User);
      staffRepo.findOne.mockResolvedValue(null);

      await expect(service.updateStaff('uuid-1', updateReq)).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('getStaffById', () => {
    it('should return staff when found', async () => {
      const mockUser = { id: 'uuid-1', role: Role.STAFF } as User;
      const mockStaff = {
        id: 'uuid-1',
        name: 'Tran Thi B',
        user: mockUser,
      } as Staff;

      staffRepo.findOne.mockResolvedValue(mockStaff);

      const result = await service.getStaffById('uuid-1');

      expect(result.id).toBe('uuid-1');
      expect(result.name).toBe('Tran Thi B');
    });

    it('should throw NotFoundException when staff not found', async () => {
      staffRepo.findOne.mockResolvedValue(null);

      await expect(service.getStaffById('uuid-999')).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});
