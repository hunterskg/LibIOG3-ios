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
      createQueryBuilder: jest.fn(),
    } as unknown as jest.Mocked<Repository<Staff>>;

    userRepo = {
      findOne: jest.fn(),
      save: jest.fn(),
      count: jest.fn(),
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

    it('should throw NotFoundException when staff user has non-staff role', async () => {
      const mockReaderUser = { id: 'uuid-1', role: Role.READER } as User;
      const mockStaff = {
        id: 'uuid-1',
        name: 'Reader In Disguise',
        user: mockReaderUser,
      } as Staff;

      staffRepo.findOne.mockResolvedValue(mockStaff);

      await expect(service.getStaffById('uuid-1')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('getStaff', () => {
    it('should return paginated staff list with filter', async () => {
      const mockUser = { id: 'uuid-1', role: Role.STAFF } as User;
      const mockStaff = {
        id: 'uuid-1',
        name: 'Tran Thi B',
        user: mockUser,
      } as Staff;

      const mockQb = {
        leftJoinAndSelect: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn().mockResolvedValue([[mockStaff], 1]),
      };

      staffRepo.createQueryBuilder.mockReturnValue(mockQb as any);

      const result = await service.getStaff({
        page: 1,
        size: 10,
        name: 'Tran',
        role: Role.STAFF,
      });

      expect(staffRepo.createQueryBuilder).toHaveBeenCalledWith('staff');
      expect(mockQb.leftJoinAndSelect).toHaveBeenCalledWith(
        'staff.user',
        'user',
      );
      expect(mockQb.andWhere).toHaveBeenCalledWith('staff.name ILIKE :name', {
        name: '%Tran%',
      });
      expect(mockQb.andWhere).toHaveBeenCalledWith('user.role = :role', {
        role: Role.STAFF,
      });
      expect(result.data.length).toBe(1);
      expect(result.total).toBe(1);
    });

    it('should parse string page and size safely in getStaff', async () => {
      const mockUser = { id: 'uuid-1', role: Role.STAFF } as User;
      const mockStaff = {
        id: 'uuid-1',
        name: 'Tran Thi B',
        user: mockUser,
      } as Staff;

      const mockQb = {
        leftJoinAndSelect: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn().mockResolvedValue([[mockStaff], '8']),
      };

      staffRepo.createQueryBuilder.mockReturnValue(mockQb as any);

      const result = await service.getStaff({
        page: '3' as any,
        size: '4' as any,
      });

      expect(mockQb.skip).toHaveBeenCalledWith(8);
      expect(mockQb.take).toHaveBeenCalledWith(4);
      expect(result.req.page).toBe(3);
      expect(result.req.size).toBe(4);
      expect(result.total).toBe(8);
    });
  });

  describe('assignRole', () => {
    it('should throw BadRequestException if admin assigns role to himself', async () => {
      await expect(
        service.assignRole('admin-1', Role.STAFF, 'admin-1'),
      ).rejects.toThrow('Admin cannot assign role to himself');
    });

    it('should throw BadRequestException for invalid role', async () => {
      await expect(
        service.assignRole('staff-1', Role.READER, 'admin-1'),
      ).rejects.toThrow('Invalid role for staff');
    });

    it('should throw NotFoundException if staff does not exist', async () => {
      staffRepo.findOne.mockResolvedValue(null);

      await expect(
        service.assignRole('staff-999', Role.ADMIN, 'admin-1'),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw BadRequestException if target user is not staff/admin', async () => {
      const mockStaff = {
        id: 'staff-1',
        user: { id: 'staff-1', role: Role.READER } as User,
      } as Staff;
      staffRepo.findOne.mockResolvedValue(mockStaff);

      await expect(
        service.assignRole('staff-1', Role.ADMIN, 'admin-1'),
      ).rejects.toThrow('Target user is not a staff member');
    });

    it('should throw BadRequestException when demoting last active admin', async () => {
      const mockAdminUser = {
        id: 'admin-2',
        role: Role.ADMIN,
        status: UserStatus.ACTIVE,
      } as User;
      const mockStaff = {
        id: 'admin-2',
        user: mockAdminUser,
      } as Staff;

      staffRepo.findOne.mockResolvedValue(mockStaff);
      userRepo.count.mockResolvedValue(1);

      await expect(
        service.assignRole('admin-2', Role.STAFF, 'admin-1'),
      ).rejects.toThrow('System must have at least one active admin');
    });

    it('should successfully assign role when conditions are met', async () => {
      const mockStaffUser = {
        id: 'staff-1',
        role: Role.STAFF,
        status: UserStatus.ACTIVE,
      } as User;
      const mockStaff = {
        id: 'staff-1',
        user: mockStaffUser,
      } as Staff;

      staffRepo.findOne.mockResolvedValue(mockStaff);
      userRepo.save.mockResolvedValue(mockStaffUser);

      await service.assignRole('staff-1', Role.ADMIN, 'admin-1');

      expect(mockStaffUser.role).toBe(Role.ADMIN);
      expect(userRepo.save).toHaveBeenCalledWith(mockStaffUser);
    });
  });
});
