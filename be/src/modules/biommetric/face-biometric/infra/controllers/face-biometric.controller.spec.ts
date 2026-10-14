jest.mock('@nestjs/typeorm', () => ({
  InjectRepository: () => () => {},
  getRepositoryToken: (entity: any) => entity,
}));

jest.mock('@nestjs/passport', () => ({
  AuthGuard: () => () => {},
}));

jest.mock('../../../../auth/infra/guard/jwt.guard', () => ({
  JwtGuard: jest.fn().mockImplementation(() => ({})),
}));

jest.mock('../../../../auth/infra/decorators/current-user.decorator', () => ({
  CurrentUser: () => () => {},
}));

jest.mock('../interceptors/face-domain-exception.interceptor', () => ({
  FaceDomainExceptionInterceptor: jest.fn().mockImplementation(() => ({})),
}));

jest.mock('@nestjs/platform-express', () => ({
  FileInterceptor: () => () => {},
}));

import { FaceBiometricController } from './face-biometric.controller';
import { FaceBiometricService } from '../../application/services/facebiometric.service';
import { UserRes } from '../../../../user/domain/dtos/res.dto';
import { Role } from '../../../../user/domain/enums/role.enum';
import { UserStatus } from '../../../../user/domain/enums/user-statis.enum';
import { FaceRegistrationStatusRes } from '../../dtos/res.dto';
import { BiometricStatus } from '../../../domain/enums/biometric-status.enum';

describe('FaceBiometricController', () => {
  let controller: FaceBiometricController;
  let service: jest.Mocked<FaceBiometricService>;

  beforeEach(() => {
    service = {
      getFaceRegistrationStatus: jest.fn(),
      registerFace: jest.fn(),
    } as unknown as jest.Mocked<FaceBiometricService>;

    controller = new FaceBiometricController(service);
  });

  describe('getFaceStatus', () => {
    it('should query own status when user is READER even if query readerId is provided', async () => {
      const readerUser: UserRes = {
        userId: 'reader-self-id',
        email: 'reader1@example.com',
        role: Role.READER,
        status: UserStatus.ACTIVE,
        createdAt: new Date(),
        updatedAt: new Date(),
        isActive: true,
      };

      const mockResponse = FaceRegistrationStatusRes.registered(
        BiometricStatus.ACTIVE,
        new Date(),
        new Date(),
      );
      service.getFaceRegistrationStatus.mockResolvedValue(mockResponse);

      const result = await controller.getFaceStatus(
        readerUser,
        'other-reader-id',
      );

      expect(service.getFaceRegistrationStatus).toHaveBeenCalledWith(
        'reader-self-id',
      );
      expect(result).toBe(mockResponse);
    });

    it('should query own status when user is STAFF and readerId query is not provided', async () => {
      const staffUser: UserRes = {
        userId: 'staff-self-id',
        email: 'staff1@example.com',
        role: Role.STAFF,
        status: UserStatus.ACTIVE,
        createdAt: new Date(),
        updatedAt: new Date(),
        isActive: true,
      };

      const mockResponse = FaceRegistrationStatusRes.notRegistered();
      service.getFaceRegistrationStatus.mockResolvedValue(mockResponse);

      const result = await controller.getFaceStatus(staffUser);

      expect(service.getFaceRegistrationStatus).toHaveBeenCalledWith(
        'staff-self-id',
      );
      expect(result).toBe(mockResponse);
    });

    it('should query target readerId when user is STAFF and readerId is provided', async () => {
      const staffUser: UserRes = {
        userId: 'staff-self-id',
        email: 'staff1@example.com',
        role: Role.STAFF,
        status: UserStatus.ACTIVE,
        createdAt: new Date(),
        updatedAt: new Date(),
        isActive: true,
      };

      const mockResponse = FaceRegistrationStatusRes.registered(
        BiometricStatus.ACTIVE,
      );
      service.getFaceRegistrationStatus.mockResolvedValue(mockResponse);

      const result = await controller.getFaceStatus(
        staffUser,
        'target-reader-id',
      );

      expect(service.getFaceRegistrationStatus).toHaveBeenCalledWith(
        'target-reader-id',
      );
      expect(result).toBe(mockResponse);
    });

    it('should query target readerId when user is ADMIN and readerId is provided', async () => {
      const adminUser: UserRes = {
        userId: 'admin-self-id',
        email: 'admin1@example.com',
        role: Role.ADMIN,
        status: UserStatus.ACTIVE,
        createdAt: new Date(),
        updatedAt: new Date(),
        isActive: true,
      };

      const mockResponse = FaceRegistrationStatusRes.registered(
        BiometricStatus.ACTIVE,
      );
      service.getFaceRegistrationStatus.mockResolvedValue(mockResponse);

      const result = await controller.getFaceStatus(
        adminUser,
        'target-reader-id-2',
      );

      expect(service.getFaceRegistrationStatus).toHaveBeenCalledWith(
        'target-reader-id-2',
      );
      expect(result).toBe(mockResponse);
    });
  });
});
