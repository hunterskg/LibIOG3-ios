import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { randomInt } from 'node:crypto';
import { DataSource, Repository } from 'typeorm';
import { Staff } from '../../../user/domain/entities/staff.entity';
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
import { DeviceAssignment } from '../../domain/entities/device-assignment.entity';
import { AssignmentStatus } from '../../domain/enums/assignment-status.enum';

const ACTIVATION_CODE_TTL_MS = 24 * 60 * 60 * 1000;

@Injectable()
export class DeviceService {
  constructor(
    @InjectRepository(DeviceAssignment)
    private readonly assignmentRepo: Repository<DeviceAssignment>,
    @InjectRepository(Staff)
    private readonly staffRepo: Repository<Staff>,
    private readonly dataSource: DataSource,
  ) {}

  async assign(
    req: AssignDeviceReq,
    adminId: string,
  ): Promise<AssignDeviceRes> {
    const staff = await this.staffRepo.findOne({
      where: { id: req.staffId },
      relations: { user: true },
    });

    if (!staff || !staff.user || staff.user.role !== Role.STAFF) {
      throw new NotFoundException('Staff not found');
    }

    const assignment = await this.dataSource.transaction(async (manager) => {
      await manager.update(
        DeviceAssignment,
        { staffId: req.staffId, status: AssignmentStatus.ACTIVE },
        { status: AssignmentStatus.REVOKED, revokedAt: new Date() },
      );

      const pendingAssignments = await manager.find(DeviceAssignment, {
        where: { staffId: req.staffId, status: AssignmentStatus.PENDING },
      });
      for (const pending of pendingAssignments) {
        pending.status = AssignmentStatus.REVOKED;
        pending.revokedAt = new Date();
      }
      await manager.save(DeviceAssignment, pendingAssignments);

      return manager.save(
        DeviceAssignment,
        manager.create(DeviceAssignment, {
          staffId: req.staffId,
          assignedById: adminId,
          activationCode: await this.createUniqueCode(manager),
          status: AssignmentStatus.PENDING,
          expiresAt: new Date(Date.now() + ACTIVATION_CODE_TTL_MS),
        }),
      );
    });

    return {
      activationCode: assignment.activationCode,
      assignment: DeviceAssignmentRes.of(assignment),
    };
  }

  async activate(req: ActivateDeviceReq): Promise<ActivateDeviceRes> {
    const assignment = await this.assignmentRepo.findOne({
      where: { activationCode: req.activationCode },
    });

    if (!assignment || assignment.status !== AssignmentStatus.PENDING) {
      throw new BadRequestException(
        'Activation code is invalid or already used',
      );
    }
    if (assignment.expiresAt <= new Date()) {
      throw new BadRequestException('Activation code has expired');
    }

    const activeFingerprint = await this.assignmentRepo.findOne({
      where: {
        deviceFingerprint: req.deviceFingerprint,
        status: AssignmentStatus.ACTIVE,
      },
    });
    if (activeFingerprint) {
      throw new ConflictException(
        'Device is already assigned to another account',
      );
    }

    assignment.deviceFingerprint = req.deviceFingerprint;
    assignment.deviceName = req.deviceName;
    assignment.devicePlatform = req.devicePlatform;
    assignment.status = AssignmentStatus.ACTIVE;
    assignment.activatedAt = new Date();
    const saved = await this.assignmentRepo.save(assignment);

    return {
      message: 'Device activated successfully',
      assignment: DeviceAssignmentRes.of(saved),
    };
  }

  async revoke(id: string): Promise<void> {
    const assignment = await this.assignmentRepo.findOne({ where: { id } });
    if (!assignment) {
      throw new NotFoundException('Device assignment not found');
    }
    if (assignment.status === AssignmentStatus.REVOKED) return;
    assignment.status = AssignmentStatus.REVOKED;
    assignment.revokedAt = new Date();
    await this.assignmentRepo.save(assignment);
  }

  async list(req: QueryAssignmentReq): Promise<DeviceAssignmentRes[]> {
    const assignments = await this.assignmentRepo.find({
      where: {
        ...(req.staffId ? { staffId: req.staffId } : {}),
        ...(req.status ? { status: req.status } : {}),
      },
      order: { createdAt: 'DESC' },
    });
    return assignments.map(DeviceAssignmentRes.of);
  }

  async listForStaff(staffId: string): Promise<DeviceAssignmentRes[]> {
    const assignments = await this.assignmentRepo.find({
      where: { staffId },
      order: { createdAt: 'DESC' },
    });
    return assignments.map(DeviceAssignmentRes.of);
  }

  private async createUniqueCode(
    manager: ReturnType<DataSource['createEntityManager']>,
  ): Promise<string> {
    for (;;) {
      const code = randomInt(100000, 1000000).toString();
      const existing = await manager.findOne(DeviceAssignment, {
        where: { activationCode: code, status: AssignmentStatus.PENDING },
      });
      if (!existing) return code;
    }
  }
}
