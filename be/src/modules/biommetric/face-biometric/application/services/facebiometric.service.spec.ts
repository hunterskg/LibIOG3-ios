jest.mock('@nestjs/typeorm', () => ({
  InjectRepository: () => () => {},
  getRepositoryToken: (entity: any) => entity,
}));

import { FaceBiometricService } from './facebiometric.service';
import { BiometricProfile } from '../../../domain/entities/biometric-profile.entity';
import { FaceProfile } from '../../domain/entities/face-profile.entity';
import { BiometricStatus } from '../../../domain/enums/biometric-status.enum';
import { Repository } from 'typeorm';

describe('FaceBiometricService', () => {
  let service: FaceBiometricService;
  let biometricProfileRepo: jest.Mocked<Repository<BiometricProfile>>;
  let faceProfileRepo: jest.Mocked<Repository<FaceProfile>>;

  beforeEach(() => {
    biometricProfileRepo = {
      findOne: jest.fn(),
    } as unknown as jest.Mocked<Repository<BiometricProfile>>;

    faceProfileRepo = {
      findOne: jest.fn(),
    } as unknown as jest.Mocked<Repository<FaceProfile>>;

    const mockCheckLivenessService = {} as any;
    const mockDetectFaceService = {} as any;
    const mockExtractEmbeddingService = {} as any;
    const mockVerifyFaceService = {} as any;
    const mockCacheService = {} as any;
    const mockDataSource = {} as any;

    service = new FaceBiometricService(
      mockCheckLivenessService,
      mockDetectFaceService,
      mockExtractEmbeddingService,
      mockVerifyFaceService,
      biometricProfileRepo,
      faceProfileRepo,
      mockCacheService,
      mockDataSource,
    );
  });

  describe('getFaceRegistrationStatus', () => {
    const readerId = '11111111-1111-1111-1111-111111111111';

    it('should return notRegistered when biometric profile does not exist', async () => {
      biometricProfileRepo.findOne.mockResolvedValue(null);

      const result = await service.getFaceRegistrationStatus(readerId);

      expect(result.isRegistered).toBe(false);
      expect(result.status).toBeUndefined();
      expect(biometricProfileRepo.findOne).toHaveBeenCalledWith({
        where: { readerId },
      });
    });

    it('should return notRegistered when biometric profile is inactive', async () => {
      const mockProfile = {
        id: 'bio-id-1',
        readerId,
        status: BiometricStatus.INACTIVE,
        consentGiven: true,
        isActive: () => false,
      } as unknown as BiometricProfile;

      biometricProfileRepo.findOne.mockResolvedValue(mockProfile);

      const result = await service.getFaceRegistrationStatus(readerId);

      expect(result.isRegistered).toBe(false);
      expect(faceProfileRepo.findOne).not.toHaveBeenCalled();
    });

    it('should return notRegistered when biometric profile active but faceProfile missing', async () => {
      const mockProfile = {
        id: 'bio-id-1',
        readerId,
        status: BiometricStatus.ACTIVE,
        consentGiven: true,
        isActive: () => true,
      } as unknown as BiometricProfile;

      biometricProfileRepo.findOne.mockResolvedValue(mockProfile);
      faceProfileRepo.findOne.mockResolvedValue(null);

      const result = await service.getFaceRegistrationStatus(readerId);

      expect(result.isRegistered).toBe(false);
      expect(faceProfileRepo.findOne).toHaveBeenCalledWith({
        where: { biometricProfileId: mockProfile.id },
      });
    });

    it('should return registered when profile is active and faceProfile exists', async () => {
      const consentAt = new Date('2026-10-10T10:00:00.000Z');
      const updatedAt = new Date('2026-10-10T12:00:00.000Z');
      const mockProfile = {
        id: 'bio-id-1',
        readerId,
        status: BiometricStatus.ACTIVE,
        consentGiven: true,
        consentAt,
        createdAt: consentAt,
        updatedAt,
        isActive: () => true,
      } as unknown as BiometricProfile;

      const mockFaceProfile = {
        faceProfileId: 'face-id-1',
        biometricProfileId: mockProfile.id,
        updatedAt,
      } as unknown as FaceProfile;

      biometricProfileRepo.findOne.mockResolvedValue(mockProfile);
      faceProfileRepo.findOne.mockResolvedValue(mockFaceProfile);

      const result = await service.getFaceRegistrationStatus(readerId);

      expect(result.isRegistered).toBe(true);
      expect(result.status).toBe(BiometricStatus.ACTIVE);
      expect(result.registeredAt).toEqual(consentAt);
      expect(result.updatedAt).toEqual(updatedAt);
    });
  });
});
