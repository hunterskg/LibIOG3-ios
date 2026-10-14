import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { randomInt } from 'node:crypto';
import { DataSource, Repository } from 'typeorm';
import { User } from '../../../user/domain/entities/user.entity';
import { Role } from '../../../user/domain/enums/role.enum';
import {
  ActivateDeviceReq,
  AssignDeviceReq,
  QueryAssignmentReq,
} from '../../domain/dtos/req.dto';
import {
  ActivateDeviceRes,
  AssignDeviceRes,
  DeviceAssignmentRes,
} from '../../domain/dtos/res.dto';
import { Device } from '../../domain/entities/device.entity';
import { DeviceStatus } from '../../domain/enums/device-status.enum';

const ACTIVATION_CODE_TTL_MS = 24 * 60 * 60 * 1000;

@Injectable()
export class DeviceService {
  constructor(
    @InjectRepository(Device)
    private readonly deviceRepo: Repository<Device>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly dataSource: DataSource,
  ) {}

  async assign(
    req: AssignDeviceReq,
    adminId: string,
  ): Promise<AssignDeviceRes> {
    const user = await this.userRepo.findOne({
      where: { id: req.staffId },
    });

    if (!user || (user.role !== Role.STAFF && user.role !== Role.ADMIN)) {
      throw new NotFoundException('Staff not found');
    }

    const device = await this.dataSource.transaction(async (manager) => {
      await manager.update(
        Device,
        { staffId: req.staffId, status: DeviceStatus.ACTIVE },
        { status: DeviceStatus.REVOKED, revokedAt: new Date() },
      );

      const pendingDevices = await manager.find(Device, {
        where: { staffId: req.staffId, status: DeviceStatus.PENDING },
      });
      for (const pending of pendingDevices) {
        pending.status = DeviceStatus.REVOKED;
        pending.revokedAt = new Date();
      }
      await manager.save(Device, pendingDevices);

      const code = await this.createUniqueCode(manager);

      return manager.save(
        Device,
        manager.create(Device, {
          staffId: req.staffId,
          gateId: req.gateId,
          deviceName: req.deviceName || 'Staff Device',
          assignedById: adminId,
          activationCode: code,
          status: DeviceStatus.PENDING,
          expiredAt: new Date(Date.now() + ACTIVATION_CODE_TTL_MS),
        }),
      );
    });

    return {
      activationCode: device.activationCode,
      assignment: DeviceAssignmentRes.of(device),
    };
  }

  async activate(req: ActivateDeviceReq): Promise<ActivateDeviceRes> {
    const device = await this.deviceRepo.findOne({
      where: { activationCode: req.activationCode },
    });

    if (!device || device.status !== DeviceStatus.PENDING) {
      throw new BadRequestException(
        'Activation code is invalid or already used',
      );
    }
    if (device.expiredAt && device.expiredAt <= new Date()) {
      throw new BadRequestException('Activation code has expired');
    }

    const activeFingerprint = await this.deviceRepo.findOne({
      where: {
        deviceFingerprint: req.deviceFingerprint,
        status: DeviceStatus.ACTIVE,
      },
    });
    if (activeFingerprint) {
      throw new ConflictException(
        'Device is already assigned to another account',
      );
    }

    device.deviceFingerprint = req.deviceFingerprint;
    if (req.deviceName) {
      device.deviceName = req.deviceName;
    }
    device.devicePlatform = req.devicePlatform;
    device.status = DeviceStatus.ACTIVE;
    device.activatedAt = new Date();
    const saved = await this.deviceRepo.save(device);

    return {
      message: 'Device activated successfully',
      assignment: DeviceAssignmentRes.of(saved),
    };
  }

  async revoke(id: string): Promise<void> {
    const device = await this.deviceRepo.findOne({ where: { id } });
    if (!device) {
      throw new NotFoundException('Device assignment not found');
    }
    if (device.status === DeviceStatus.REVOKED) return;
    device.status = DeviceStatus.REVOKED;
    device.revokedAt = new Date();
    await this.deviceRepo.save(device);
  }

  async list(req: QueryAssignmentReq): Promise<DeviceAssignmentRes[]> {
    const devices = await this.deviceRepo.find({
      where: {
        ...(req.staffId ? { staffId: req.staffId } : {}),
        ...(req.status ? { status: req.status } : {}),
      },
      order: { createdAt: 'DESC' },
    });
    return devices.map(DeviceAssignmentRes.of);
  }

  async listForStaff(staffId: string): Promise<DeviceAssignmentRes[]> {
    const devices = await this.deviceRepo.find({
      where: { staffId },
      order: { createdAt: 'DESC' },
    });
    return devices.map(DeviceAssignmentRes.of);
  }

  private async createUniqueCode(
    manager: ReturnType<DataSource['createEntityManager']>,
  ): Promise<string> {
    for (;;) {
      const code = randomInt(100000, 1000000).toString();
      const existing = await manager.findOne(Device, {
        where: { activationCode: code, status: DeviceStatus.PENDING },
      });
      if (!existing) return code;
    }
  }
}
