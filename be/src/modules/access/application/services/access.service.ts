import {
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, Repository } from 'typeorm';
import { AccessLog } from '../../domain/entities/access-log.entity';
import { AccessAction } from '../../domain/enums/access-action.enum';
import { AccessMethod } from '../../domain/enums/access-method.enum';
import { AccessResult } from '../../domain/enums/access-result.enum';
import { User } from '../../../user/domain/entities/user.entity';
import { Role } from '../../../user/domain/enums/role.enum';
import { UserStatus } from '../../../user/domain/enums/user-statis.enum';
import { Device } from '../../../device/domain/entities/device.entity';
import { Gate } from '../../../device/domain/entities/gate.entity';
import { DeviceStatus } from '../../../device/domain/enums/device-status.enum';
import { GateStatus } from '../../../device/domain/enums/gate-status.enum';
import { LibrarySchedule } from '../../../library/domain/entities/library-schedule.entity';
import { ScheduleType } from '../../../library/domain/enums/schedule-type.enum';
import {
  QueryAccessLogsDto,
  ReportSummaryQueryDto,
  TriggerClosureDto,
} from '../../infra/dto/access-query.dto';

export interface ActiveReaderItem {
  readerId: string;
  fullName: string;
  email: string;
  checkedInAt: Date;
  method: AccessMethod;
  gateName?: string;
  accessLogId: string;
}

@Injectable()
export class AccessService {
  constructor(
    @InjectRepository(AccessLog)
    private readonly accessLogRepo: Repository<AccessLog>,
    @InjectRepository(LibrarySchedule)
    private readonly scheduleRepo: Repository<LibrarySchedule>,
    private readonly dataSource: DataSource,
  ) {}

  /**
   * Lấy danh sách bạn đọc hiện đang ở TRONG thư viện (bản ghi SUCCESS mới nhất là CHECK_IN).
   */
  async getActiveReaders(): Promise<ActiveReaderItem[]> {
    const logs = await this.accessLogRepo.find({
      where: { result: AccessResult.SUCCESS },
      relations: { reader: true, gate: true },
      order: { occurredAt: 'DESC', createdAt: 'DESC', id: 'DESC' },
    });

    const latestByReader = new Map<string, AccessLog>();
    for (const log of logs) {
      if (!latestByReader.has(log.readerId)) {
        latestByReader.set(log.readerId, log);
      }
    }

    const activeReaders: ActiveReaderItem[] = [];
    for (const log of latestByReader.values()) {
      if (log.action === AccessAction.CHECK_IN && log.reader) {
        activeReaders.push({
          readerId: log.readerId,
          fullName: log.reader.fullName,
          email: log.reader.email,
          checkedInAt: log.occurredAt,
          method: log.method,
          gateName: log.gate?.name,
          accessLogId: log.id,
        });
      }
    }

    return activeReaders;
  }

  /**
   * Đóng cửa thư viện & Tự động AUTO_CHECK_OUT toàn bộ bạn đọc còn đang ở trong thư viện.
   */
  async triggerClosure(adminId: string, dto: TriggerClosureDto) {
    const now = new Date();
    const reason =
      dto.reason?.trim() || 'Đóng cửa thư viện - Tự động check-out cuối ngày';

    return this.dataSource.transaction(async (manager) => {
      const userRepo = manager.getRepository(User);
      const accessLogRepo = manager.getRepository(AccessLog);
      const deviceRepo = manager.getRepository(Device);
      const gateRepo = manager.getRepository(Gate);
      const scheduleRepo = manager.getRepository(LibrarySchedule);

      const admin = await userRepo.findOne({
        where: { id: adminId, status: UserStatus.ACTIVE },
      });
      if (!admin || (admin.role !== Role.ADMIN && admin.role !== Role.STAFF)) {
        throw new ForbiddenException('Không có quyền thực hiện đóng cửa.');
      }

      // Tìm tất cả bạn đọc đang ở trạng thái IN
      const allSuccessLogs = await accessLogRepo.find({
        where: { result: AccessResult.SUCCESS },
        relations: { reader: true },
        order: { occurredAt: 'DESC', createdAt: 'DESC', id: 'DESC' },
      });

      const latestByReader = new Map<string, AccessLog>();
      for (const log of allSuccessLogs) {
        if (!latestByReader.has(log.readerId)) {
          latestByReader.set(log.readerId, log);
        }
      }

      const activeCheckInLogs = Array.from(latestByReader.values()).filter(
        (l) => l.action === AccessAction.CHECK_IN,
      );

      // Chuẩn bị thiết bị/cổng fallback nếu cần
      let fallbackDevice = await deviceRepo.findOne({
        where: {},
        order: { createdAt: 'DESC' },
      });
      let fallbackGate = fallbackDevice?.gateId
        ? await gateRepo.findOne({ where: { id: fallbackDevice.gateId } })
        : null;

      if (!fallbackGate) {
        fallbackGate = await gateRepo.findOne({
          where: { code: 'MANUAL-DESK' },
        });
        if (!fallbackGate) {
          fallbackGate = await gateRepo.save(
            gateRepo.create({
              code: 'MANUAL-DESK',
              name: 'Quầy thủ thư (Duyệt thủ công)',
              location: 'Sảnh chính',
              status: GateStatus.ACTIVE,
            }),
          );
        }
      }

      if (!fallbackDevice) {
        fallbackDevice = await deviceRepo.save(
          deviceRepo.create({
            staffId: admin.id,
            gateId: fallbackGate.id,
            deviceName: 'Quầy thủ thư (Manual Desk)',
            devicePlatform: 'WEB/ADMIN',
            status: DeviceStatus.ACTIVE,
            assignedById: admin.id,
            assignedAt: now,
            activatedAt: now,
          }),
        );
      }

      const createdLogs: AccessLog[] = [];
      for (const checkInLog of activeCheckInLogs) {
        const autoOut = accessLogRepo.create({
          readerId: checkInLog.readerId,
          staffId: admin.id,
          deviceId: checkInLog.deviceId || fallbackDevice.id,
          gateId: checkInLog.gateId || fallbackGate.id,
          action: AccessAction.AUTO_CHECK_OUT,
          method: AccessMethod.MANUAL,
          result: AccessResult.SUCCESS,
          reason,
          occurredAt: now,
        });
        createdLogs.push(await accessLogRepo.save(autoOut));
      }

      // Nếu chọn đánh dấu đóng cửa ngày hôm nay trong lịch đặc biệt
      if (dto.markTodayClosed) {
        const y = now.getFullYear();
        const m = `${now.getMonth() + 1}`.padStart(2, '0');
        const d = `${now.getDate()}`.padStart(2, '0');
        const todayStr = `${y}-${m}-${d}`;

        let specialToday = await scheduleRepo.findOne({
          where: { type: ScheduleType.SPECIAL, specificDate: todayStr },
        });

        if (specialToday) {
          specialToday.isClosed = true;
          specialToday.openTime = null;
          specialToday.closeTime = null;
          specialToday.note = reason;
          specialToday.isActive = true;
          await scheduleRepo.save(specialToday);
        } else {
          specialToday = scheduleRepo.create({
            type: ScheduleType.SPECIAL,
            specificDate: todayStr,
            dayOfWeek: null,
            openTime: null,
            closeTime: null,
            isClosed: true,
            note: reason,
            isActive: true,
          });
          await scheduleRepo.save(specialToday);
        }
      }

      return {
        success: true,
        message: `Đã đóng cửa thư viện và tự động check-out ${createdLogs.length} bạn đọc.`,
        closedAt: now,
        reason,
        autoCheckedOutCount: createdLogs.length,
        affectedReaders: activeCheckInLogs.map((l) => ({
          readerId: l.readerId,
          fullName: l.reader?.fullName ?? '---',
          email: l.reader?.email ?? '---',
          checkedInAt: l.occurredAt,
        })),
      };
    });
  }

  /**
   * Truy vấn lịch sử ra/vào có phân trang và bộ lọc.
   */
  async getAccessLogs(query: QueryAccessLogsDto) {
    const page = Math.max(1, Number(query.page) || 1);
    const size = Math.min(100, Math.max(1, Number(query.size) || 20));

    const qb = this.accessLogRepo
      .createQueryBuilder('log')
      .leftJoinAndSelect('log.reader', 'reader')
      .leftJoinAndSelect('log.staff', 'staff')
      .leftJoinAndSelect('log.gate', 'gate')
      .leftJoinAndSelect('log.device', 'device');

    if (query.action) {
      qb.andWhere('log.action = :action', { action: query.action });
    }
    if (query.method) {
      qb.andWhere('log.method = :method', { method: query.method });
    }
    if (query.result) {
      qb.andWhere('log.result = :result', { result: query.result });
    }
    if (query.readerId) {
      qb.andWhere('log.readerId = :readerId', { readerId: query.readerId });
    }
    if (query.search?.trim()) {
      const s = `%${query.search.trim().toLowerCase()}%`;
      qb.andWhere(
        '(LOWER(reader.fullName) LIKE :s OR LOWER(reader.email) LIKE :s OR LOWER(log.reason) LIKE :s)',
        { s },
      );
    }
    if (query.from) {
      qb.andWhere('log.occurredAt >= :from', { from: new Date(query.from) });
    }
    if (query.to) {
      qb.andWhere('log.occurredAt <= :to', { to: new Date(query.to) });
    }

    qb.orderBy('log.occurredAt', 'DESC')
      .addOrderBy('log.createdAt', 'DESC')
      .skip((page - 1) * size)
      .take(size);

    const [items, total] = await qb.getManyAndCount();

    return {
      data: items.map((item) => ({
        id: item.id,
        readerId: item.readerId,
        readerName: item.reader?.fullName ?? '---',
        readerEmail: item.reader?.email ?? '---',
        staffId: item.staffId,
        staffName: item.staff?.fullName ?? null,
        gateId: item.gateId,
        gateName: item.gate?.name ?? null,
        deviceId: item.deviceId,
        deviceName: item.device?.deviceName ?? null,
        action: item.action,
        method: item.method,
        result: item.result,
        reason: item.reason,
        occurredAt: item.occurredAt,
        createdAt: item.createdAt,
      })),
      page,
      size,
      total,
      totalPages: Math.ceil(total / size),
    };
  }

  /**
   * Thống kê & Báo cáo tổng hợp vận hành thư viện.
   */
  async getReportSummary(query: ReportSummaryQueryDto) {
    const now = new Date();
    const fromDate = query.from
      ? new Date(query.from)
      : new Date(now.getFullYear(), now.getMonth(), now.getDate() - 6, 0, 0, 0);
    const toDate = query.to
      ? new Date(query.to)
      : new Date(
          now.getFullYear(),
          now.getMonth(),
          now.getDate(),
          23,
          59,
          59,
          999,
        );

    const logs = await this.accessLogRepo
      .createQueryBuilder('log')
      .leftJoinAndSelect('log.reader', 'reader')
      .leftJoinAndSelect('log.gate', 'gate')
      .where('log.occurredAt >= :from AND log.occurredAt <= :to', {
        from: fromDate,
        to: toDate,
      })
      .orderBy('log.occurredAt', 'DESC')
      .getMany();

    const activeReaders = await this.getActiveReaders();

    let totalCheckIns = 0;
    let totalCheckOuts = 0;
    let totalAutoCheckOuts = 0;
    let totalDenied = 0;

    const byMethod: Record<string, number> = {
      [AccessMethod.QR]: 0,
      [AccessMethod.FACE]: 0,
      [AccessMethod.MANUAL]: 0,
    };

    const dailyMap = new Map<
      string,
      {
        date: string;
        checkIns: number;
        checkOuts: number;
        autoCheckOuts: number;
      }
    >();
    const hourlyMap = new Map<number, number>();
    for (let h = 0; h < 24; h++) {
      hourlyMap.set(h, 0);
    }

    for (const log of logs) {
      if (log.result === AccessResult.DENIED) {
        totalDenied++;
      }

      if (log.action === AccessAction.CHECK_IN) {
        totalCheckIns++;
      } else if (log.action === AccessAction.CHECK_OUT) {
        totalCheckOuts++;
      } else if (log.action === AccessAction.AUTO_CHECK_OUT) {
        totalAutoCheckOuts++;
      }

      byMethod[log.method] = (byMethod[log.method] ?? 0) + 1;

      const d = new Date(log.occurredAt);
      const dateKey = `${d.getFullYear()}-${`${d.getMonth() + 1}`.padStart(2, '0')}-${`${d.getDate()}`.padStart(2, '0')}`;
      const dayEntry = dailyMap.get(dateKey) ?? {
        date: dateKey,
        checkIns: 0,
        checkOuts: 0,
        autoCheckOuts: 0,
      };
      if (log.action === AccessAction.CHECK_IN) dayEntry.checkIns++;
      else if (log.action === AccessAction.CHECK_OUT) dayEntry.checkOuts++;
      else if (log.action === AccessAction.AUTO_CHECK_OUT)
        dayEntry.autoCheckOuts++;
      dailyMap.set(dateKey, dayEntry);

      if (log.action === AccessAction.CHECK_IN) {
        const hour = d.getHours();
        hourlyMap.set(hour, (hourlyMap.get(hour) ?? 0) + 1);
      }
    }

    const dailyStats = Array.from(dailyMap.values()).sort((a, b) =>
      a.date.localeCompare(b.date),
    );
    const hourlyStats = Array.from(hourlyMap.entries()).map(
      ([hour, count]) => ({
        hour,
        count,
      }),
    );

    const recentAutoCheckOuts = logs
      .filter((l) => l.action === AccessAction.AUTO_CHECK_OUT)
      .slice(0, 10)
      .map((l) => ({
        id: l.id,
        readerId: l.readerId,
        readerName: l.reader?.fullName ?? '---',
        readerEmail: l.reader?.email ?? '---',
        reason: l.reason,
        occurredAt: l.occurredAt,
      }));

    return {
      from: fromDate.toISOString(),
      to: toDate.toISOString(),
      currentInsideCount: activeReaders.length,
      totalTransactions: logs.length,
      totalCheckIns,
      totalCheckOuts,
      totalAutoCheckOuts,
      totalDenied,
      byMethod,
      dailyStats,
      hourlyStats,
      recentAutoCheckOuts,
    };
  }
}
