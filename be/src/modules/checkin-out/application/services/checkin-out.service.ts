import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { createHash } from 'crypto';
import { DataSource } from 'typeorm';
import { AccessLog } from '../../../access/domain/entities/access-log.entity';
import { AccessAction } from '../../../access/domain/enums/access-action.enum';
import { AccessMethod } from '../../../access/domain/enums/access-method.enum';
import { AccessResult } from '../../../access/domain/enums/access-result.enum';
import { Device } from '../../../device/domain/entities/device.entity';
import { Gate } from '../../../device/domain/entities/gate.entity';
import { DeviceStatus } from '../../../device/domain/enums/device-status.enum';
import { GateStatus } from '../../../device/domain/enums/gate-status.enum';
import { QrToken } from '../../../qr/domain/entities/qr-token.entity';
import { QrTokenStatus } from '../../../qr/domain/enums/qr-token-status.enum';
import { Role } from '../../../user/domain/enums/role.enum';
import { UserStatus } from '../../../user/domain/enums/user-statis.enum';
import { User } from '../../../user/domain/entities/user.entity';
import { CheckInOutDto } from '../../infra/dto/checkin-out.dto';
import { AccessStateService, ReaderAccessState } from './access-state.service';
import { IdentifyFaceService } from '../../../biommetric/face-biometric/application/services/identify-face.service';
import {
  INTERNAL_EVENT_BUS,
  InternalEventBus,
} from '../../../infra/event/application/internal-event-bus.interface';
import { ReaderAccessEvent } from '../../domain/events/reader-access.event';

@Injectable()
export class CheckInOutService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly accessStateService: AccessStateService,
    private readonly identifyFaceService: IdentifyFaceService,
    @Inject(INTERNAL_EVENT_BUS)
    private readonly eventService: InternalEventBus,
  ) {}

  async checkInOut(staffId: string, dto: CheckInOutDto) {
    const now = new Date();
    const tokenHash = createHash('sha256').update(dto.token).digest('hex');

    return this.dataSource.transaction(async (manager) => {
      const userRepository = manager.getRepository(User);
      const qrTokenRepository = manager.getRepository(QrToken);
      const deviceRepository = manager.getRepository(Device);
      const gateRepository = manager.getRepository(Gate);
      const accessLogRepository = manager.getRepository(AccessLog);

      const staff = await userRepository.findOne({
        where: {
          id: staffId,
          role: Role.STAFF,
          status: UserStatus.ACTIVE,
        },
      });

      if (!staff) {
        throw new ForbiddenException(
          'Tài khoản nhân viên không hợp lệ hoặc đã bị vô hiệu hóa.',
        );
      }

      const qrToken = await qrTokenRepository
        .createQueryBuilder('qr')
        .innerJoinAndSelect('qr.reader', 'reader')
        .where('qr.tokenHash = :tokenHash', { tokenHash })
        .setLock('pessimistic_write')
        .getOne();

      if (!qrToken) {
        throw new NotFoundException(
          'QR token không tồn tại hoặc không hợp lệ.',
        );
      }

      if (
        qrToken.status !== QrTokenStatus.ACTIVE ||
        qrToken.usedAt ||
        qrToken.revokedAt ||
        qrToken.expiresAt <= now
      ) {
        throw new BadRequestException(
          'QR token đã hết hạn, đã bị thu hồi hoặc đã được sử dụng.',
        );
      }

      const readerId = qrToken.reader?.id;

      if (!readerId) {
        throw new BadRequestException('QR token không liên kết với Reader.');
      }

      const reader = await userRepository
        .createQueryBuilder('reader')
        .where('reader.id = :readerId', { readerId })
        .andWhere('reader.role = :role', { role: Role.READER })
        .setLock('pessimistic_write')
        .getOne();

      if (!reader) {
        throw new NotFoundException('Không tìm thấy Reader.');
      }

      if (reader.status !== UserStatus.ACTIVE) {
        throw new ForbiddenException('Tài khoản Reader đã bị vô hiệu hóa.');
      }

      const device = await deviceRepository
        .createQueryBuilder('device')
        .where('device.staffId = :staffId', { staffId })
        .andWhere('device.status = :status', {
          status: DeviceStatus.ACTIVE,
        })
        .andWhere('device.revokedAt IS NULL')
        .andWhere('(device.expiredAt IS NULL OR device.expiredAt > :now)', {
          now,
        })
        .andWhere('device.gateId IS NOT NULL')
        .orderBy('device.assignedAt', 'DESC')
        .addOrderBy('device.createdAt', 'DESC')
        .getOne();

      if (!device) {
        throw new ForbiddenException(
          `Nhân viên có ID ${staffId} chưa có thiết bị hoạt động hợp lệ được gán.`,
        );
      }

      const gate = await gateRepository.findOne({
        where: {
          id: device.gateId,
          status: GateStatus.ACTIVE,
        },
      });

      if (!gate) {
        throw new ForbiddenException(
          'Cổng được gán cho thiết bị không hoạt động.',
        );
      }

      const currentState = await this.accessStateService.getCurrentState(
        manager,
        reader.id,
      );

      const accessAction =
        currentState === ReaderAccessState.OUT
          ? AccessAction.CHECK_IN
          : AccessAction.CHECK_OUT;

      const newState =
        accessAction === AccessAction.CHECK_IN
          ? ReaderAccessState.IN
          : ReaderAccessState.OUT;

      const accessLog = accessLogRepository.create({
        readerId: reader.id,
        staffId: staff.id,
        deviceId: device.id,
        gateId: gate.id,
        action: accessAction,
        method: AccessMethod.QR,
        result: AccessResult.SUCCESS,
        occurredAt: now,
      });

      const savedLog = await accessLogRepository.save(accessLog);

      qrToken.status = QrTokenStatus.USED;
      qrToken.usedAt = now;
      await qrTokenRepository.save(qrToken);

      await this.eventService.publish(
        new ReaderAccessEvent(
          accessAction,
          reader.id,
          device.id,
          savedLog.id,
          now,
        ),
      );

      return {
        success: true,
        message:
          accessAction === AccessAction.CHECK_IN
            ? 'Check-in thành công.'
            : 'Check-out thành công.',
        data: {
          accessLogId: savedLog.id,
          readerId: reader.id,
          staffId: staff.id,
          deviceId: device.id,
          gateId: gate.id,
          action: savedLog.action,
          method: savedLog.method,
          result: savedLog.result,
          state: newState,
          occurredAt: savedLog.occurredAt,
        },
      };
    });
  }

  async checkInOutByFace(staffId: string, imageBuffer: Buffer) {
    const identity = await this.identifyFaceService.execute(imageBuffer);
    const now = new Date();

    return this.dataSource.transaction(async (manager) => {
      const userRepository = manager.getRepository(User);
      const deviceRepository = manager.getRepository(Device);
      const gateRepository = manager.getRepository(Gate);
      const accessLogRepository = manager.getRepository(AccessLog);

      const staff = await userRepository.findOne({
        where: {
          id: staffId,
          role: Role.STAFF,
          status: UserStatus.ACTIVE,
        },
      });

      if (!staff) {
        throw new ForbiddenException(
          'Tài khoản nhân viên không hợp lệ hoặc đã bị vô hiệu hóa.',
        );
      }

      const reader = await userRepository
        .createQueryBuilder('reader')
        .where('reader.id = :readerId', {
          readerId: identity.readerId,
        })
        .andWhere('reader.role = :role', {
          role: Role.READER,
        })
        .setLock('pessimistic_write')
        .getOne();

      if (!reader) {
        throw new NotFoundException('Không tìm thấy Reader.');
      }

      if (reader.status !== UserStatus.ACTIVE) {
        throw new ForbiddenException('Tài khoản Reader đã bị vô hiệu hóa.');
      }

      const device = await deviceRepository
        .createQueryBuilder('device')
        .where('device.staffId = :staffId', { staffId })
        .andWhere('device.status = :status', {
          status: DeviceStatus.ACTIVE,
        })
        .andWhere('device.revokedAt IS NULL')
        .andWhere('(device.expiredAt IS NULL OR device.expiredAt > :now)', {
          now,
        })
        .andWhere('device.gateId IS NOT NULL')
        .orderBy('device.assignedAt', 'DESC')
        .addOrderBy('device.createdAt', 'DESC')
        .getOne();

      if (!device) {
        throw new ForbiddenException(
          `Nhân viên có ID ${staffId} chưa có thiết bị hoạt động hợp lệ được gán.`,
        );
      }

      const gate = await gateRepository.findOne({
        where: {
          id: device.gateId,
          status: GateStatus.ACTIVE,
        },
      });

      if (!gate) {
        throw new ForbiddenException(
          'Cổng được gán cho thiết bị không hoạt động.',
        );
      }

      const currentState = await this.accessStateService.getCurrentState(
        manager,
        reader.id,
      );

      const accessAction =
        currentState === ReaderAccessState.OUT
          ? AccessAction.CHECK_IN
          : AccessAction.CHECK_OUT;

      const newState =
        accessAction === AccessAction.CHECK_IN
          ? ReaderAccessState.IN
          : ReaderAccessState.OUT;

      const accessLog = accessLogRepository.create({
        readerId: reader.id,
        staffId: staff.id,
        deviceId: device.id,
        gateId: gate.id,
        action: accessAction,
        method: AccessMethod.FACE,
        result: AccessResult.SUCCESS,
        occurredAt: now,
      });

      const savedLog = await accessLogRepository.save(accessLog);

      await this.eventService.publish(
        new ReaderAccessEvent(
          accessAction,
          reader.id,
          device.id,
          savedLog.id,
          now,
        ),
      );

      return {
        success: true,
        message:
          accessAction === AccessAction.CHECK_IN
            ? 'Face check-in thành công.'
            : 'Face check-out thành công.',
        data: {
          accessLogId: savedLog.id,
          readerId: reader.id,
          staffId: staff.id,
          deviceId: device.id,
          gateId: gate.id,
          action: savedLog.action,
          method: savedLog.method,
          result: savedLog.result,
          state: newState,
          occurredAt: savedLog.occurredAt,
          similarity: identity.similarity,
        },
      };
    });
  }
}
