import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../../user/domain/entities/user.entity';
import { Role } from '../../../user/domain/enums/role.enum';
import {
  QueryAssignmentReq,
} from '../../domain/dtos/req.dto';
import {
  DeviceAssignmentRes,
} from '../../domain/dtos/res.dto';
import { Device } from '../../domain/entities/device.entity';
import { DeviceStatus } from '../../domain/enums/device-status.enum';
import { Gate } from '../../domain/entities/gate.entity';
import { GateStatus } from '../../domain/enums/gate-status.enum';

@Injectable()
export class DeviceService {
  constructor(
    @InjectRepository(Device)
    private readonly deviceRepo: Repository<Device>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(Gate)
    private readonly gateRepo: Repository<Gate>,
  ) {}

  async verifyOrBindStaffDevice(
    staffId: string,
    fingerprint: string,
    deviceName?: string,
    platform?: string,
  ): Promise<void> {
    const existing = await this.deviceRepo.findOne({ where: { staffId, status: DeviceStatus.ACTIVE } });
    if (existing) {
      if (existing.deviceFingerprint !== fingerprint) {
        throw new ConflictException('Tài khoản đã được gắn với thiết bị khác. Liên hệ Admin để đổi thiết bị.');
      }
      return;
    }
    const used = await this.deviceRepo.findOne({ where: { deviceFingerprint: fingerprint, status: DeviceStatus.ACTIVE } });
    if (used && used.staffId !== staffId) throw new ConflictException('Thiết bị đã được gắn với tài khoản khác');
    await this.deviceRepo.save(this.deviceRepo.create({
      staffId, gateId: null,
      deviceFingerprint: fingerprint, deviceName: deviceName || 'Staff Device', devicePlatform: platform,
      status: DeviceStatus.ACTIVE, assignedById: staffId, activatedAt: new Date(),
    }));
  }

  async unbindStaff(staffId: string): Promise<void> {
    const device = await this.deviceRepo.findOne({ where: { staffId, status: DeviceStatus.ACTIVE } });
    if (!device) throw new NotFoundException('Staff has no active device');
    device.status = DeviceStatus.REVOKED;
    device.revokedAt = new Date();
    await this.deviceRepo.save(device);
  }

  async assignGate(staffId: string, gateId: string): Promise<void> {
    const gate = await this.gateRepo.findOne({ where: { id: gateId, status: GateStatus.ACTIVE } });
    if (!gate) throw new NotFoundException('Active gate not found');
    const staff = await this.userRepo.findOne({ where: { id: staffId, role: Role.STAFF } });
    if (!staff) throw new NotFoundException('Staff not found');
    const device = await this.deviceRepo.findOne({ where: { staffId, status: DeviceStatus.ACTIVE } });
    if (!device) throw new NotFoundException('Staff has no active device');
    device.gateId = gateId;
    await this.deviceRepo.save(device);
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
      relations: { gate: true },
    });
    return devices.map(DeviceAssignmentRes.of);
  }

  async listForStaff(staffId: string): Promise<DeviceAssignmentRes[]> {
    const devices = await this.deviceRepo.find({
      where: { staffId },
      order: { createdAt: 'DESC' },
      relations: { gate: true },
    });
    return devices.map(DeviceAssignmentRes.of);
  }

}
