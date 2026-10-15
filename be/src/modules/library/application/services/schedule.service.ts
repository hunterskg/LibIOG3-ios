import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { LibrarySchedule } from '../../domain/entities/library-schedule.entity';
import { ScheduleType } from '../../domain/enums/schedule-type.enum';
import {
  CreateScheduleDto,
  UpdateScheduleDto,
  WeeklyDayDto,
} from '../../infra/dto/schedule.dto';

export interface OpenStatus {
  isOpen: boolean;
  // Lý do: OPEN | CLOSED_ALL_DAY | OUTSIDE_HOURS | NO_SCHEDULE
  reason: string;
  checkedAt: string;
  scheduleId?: string;
}

@Injectable()
export class ScheduleService {
  constructor(
    @InjectRepository(LibrarySchedule)
    private readonly scheduleRepo: Repository<LibrarySchedule>,
  ) {}

  async create(dto: CreateScheduleDto): Promise<LibrarySchedule> {
    this.validatePayload(dto);

    const schedule = this.scheduleRepo.create({
      type: dto.type,
      dayOfWeek: dto.type === ScheduleType.WEEKLY ? dto.dayOfWeek : null,
      specificDate: dto.type === ScheduleType.SPECIAL ? dto.specificDate : null,
      openTime: dto.isClosed ? null : this.normalizeTime(dto.openTime),
      closeTime: dto.isClosed ? null : this.normalizeTime(dto.closeTime),
      isClosed: dto.isClosed ?? false,
      note: dto.note ?? null,
    });

    return this.scheduleRepo.save(schedule);
  }

  findAll(): Promise<LibrarySchedule[]> {
    return this.scheduleRepo.find({
      order: { type: 'ASC', dayOfWeek: 'ASC', specificDate: 'ASC' },
    });
  }

  /** Lịch hàng tuần (7 dòng), sắp theo thứ. */
  findWeekly(): Promise<LibrarySchedule[]> {
    return this.scheduleRepo.find({
      where: { type: ScheduleType.WEEKLY },
      order: { dayOfWeek: 'ASC' },
    });
  }

  /** Các ngày đặc biệt (lễ, đóng cửa đột xuất...), sắp theo ngày. */
  findSpecial(): Promise<LibrarySchedule[]> {
    return this.scheduleRepo.find({
      where: { type: ScheduleType.SPECIAL },
      order: { specificDate: 'ASC' },
    });
  }

  /**
   * Ghi đè toàn bộ lịch hàng tuần trong một giao dịch: xóa hết dòng WEEKLY cũ
   * rồi chèn lại danh sách mới. Tránh trạng thái lưu nửa chừng.
   */
  async setWeekly(days: WeeklyDayDto[]): Promise<LibrarySchedule[]> {
    const seen = new Set<number>();
    for (const day of days) {
      if (day.dayOfWeek < 0 || day.dayOfWeek > 6) {
        throw new BadRequestException(`dayOfWeek không hợp lệ: ${day.dayOfWeek}`);
      }
      if (seen.has(day.dayOfWeek)) {
        throw new BadRequestException(`dayOfWeek trùng: ${day.dayOfWeek}`);
      }
      seen.add(day.dayOfWeek);

      if (!day.isClosed) {
        const open = this.normalizeTime(day.openTime);
        const close = this.normalizeTime(day.closeTime);
        if (!open || !close) {
          throw new BadRequestException(
            `Thứ ${day.dayOfWeek}: cần giờ mở và giờ đóng khi không đóng cửa`,
          );
        }
        if (open >= close) {
          throw new BadRequestException(
            `Thứ ${day.dayOfWeek}: giờ mở phải trước giờ đóng`,
          );
        }
      }
    }

    return this.scheduleRepo.manager.transaction(async (em) => {
      await em.delete(LibrarySchedule, { type: ScheduleType.WEEKLY });

      const rows = days.map((day) =>
        em.create(LibrarySchedule, {
          type: ScheduleType.WEEKLY,
          dayOfWeek: day.dayOfWeek,
          specificDate: null,
          openTime: day.isClosed ? null : this.normalizeTime(day.openTime),
          closeTime: day.isClosed ? null : this.normalizeTime(day.closeTime),
          isClosed: day.isClosed,
        }),
      );
      await em.save(rows);

      return em.find(LibrarySchedule, {
        where: { type: ScheduleType.WEEKLY },
        order: { dayOfWeek: 'ASC' },
      });
    });
  }

  async findOne(id: string): Promise<LibrarySchedule> {
    const schedule = await this.scheduleRepo.findOne({ where: { id } });
    if (!schedule) {
      throw new NotFoundException(`Schedule ${id} not found`);
    }
    return schedule;
  }

  async update(id: string, dto: UpdateScheduleDto): Promise<LibrarySchedule> {
    const schedule = await this.findOne(id);
    const merged = { ...schedule, ...dto } as LibrarySchedule;
    this.validatePayload(merged);

    if (dto.type !== undefined) schedule.type = dto.type;
    if (dto.dayOfWeek !== undefined) schedule.dayOfWeek = dto.dayOfWeek;
    if (dto.specificDate !== undefined) schedule.specificDate = dto.specificDate;
    if (dto.openTime !== undefined) schedule.openTime = this.normalizeTime(dto.openTime);
    if (dto.closeTime !== undefined) schedule.closeTime = this.normalizeTime(dto.closeTime);
    if (dto.isClosed !== undefined) schedule.isClosed = dto.isClosed;
    if (dto.note !== undefined) schedule.note = dto.note;
    if (dto.isActive !== undefined) schedule.isActive = dto.isActive;

    // Đóng cả ngày thì xóa giờ cho nhất quán.
    if (schedule.isClosed) {
      schedule.openTime = null;
      schedule.closeTime = null;
    }

    return this.scheduleRepo.save(schedule);
  }

  async remove(id: string): Promise<void> {
    const schedule = await this.findOne(id);
    await this.scheduleRepo.remove(schedule);
  }

  /**
   * Câu hỏi lõi cho luồng check-in: tại thời điểm `at`, thư viện có mở không?
   * Ưu tiên lịch SPECIAL của đúng ngày, nếu không có thì xét lịch WEEKLY theo thứ.
   */
  async getStatusAt(at: Date): Promise<OpenStatus> {
    const dateStr = this.toDateString(at);
    const timeStr = this.toTimeString(at);
    const dayOfWeek = at.getDay();

    const special = await this.scheduleRepo.findOne({
      where: {
        type: ScheduleType.SPECIAL,
        specificDate: dateStr,
        isActive: true,
      },
    });

    const matched =
      special ??
      (await this.scheduleRepo.findOne({
        where: {
          type: ScheduleType.WEEKLY,
          dayOfWeek,
          isActive: true,
        },
      }));

    if (!matched) {
      return { isOpen: false, reason: 'NO_SCHEDULE', checkedAt: at.toISOString() };
    }

    if (matched.isClosed) {
      return {
        isOpen: false,
        reason: 'CLOSED_ALL_DAY',
        checkedAt: at.toISOString(),
        scheduleId: matched.id,
      };
    }

    // Không khai báo giờ => coi như mở cả ngày.
    const open = matched.openTime;
    const close = matched.closeTime;
    const withinHours =
      !open || !close || (timeStr >= open && timeStr < close);

    return {
      isOpen: withinHours,
      reason: withinHours ? 'OPEN' : 'OUTSIDE_HOURS',
      checkedAt: at.toISOString(),
      scheduleId: matched.id,
    };
  }

  private validatePayload(dto: {
    type: ScheduleType;
    dayOfWeek?: number | null;
    specificDate?: string | null;
    openTime?: string | null;
    closeTime?: string | null;
    isClosed?: boolean | null;
  }): void {
    if (dto.type === ScheduleType.WEEKLY && (dto.dayOfWeek === null || dto.dayOfWeek === undefined)) {
      throw new BadRequestException('WEEKLY schedule cần dayOfWeek (0-6)');
    }
    if (dto.type === ScheduleType.SPECIAL && !dto.specificDate) {
      throw new BadRequestException('SPECIAL schedule cần specificDate (YYYY-MM-DD)');
    }

    if (!dto.isClosed && dto.openTime && dto.closeTime) {
      const open = this.normalizeTime(dto.openTime)!;
      const close = this.normalizeTime(dto.closeTime)!;
      if (open >= close) {
        throw new BadRequestException('openTime phải trước closeTime');
      }
    }
  }

  private normalizeTime(time?: string | null): string | null {
    if (!time) return null;
    // "HH:MM" -> "HH:MM:00"
    return time.length === 5 ? `${time}:00` : time;
  }

  private toDateString(d: Date): string {
    const y = d.getFullYear();
    const m = `${d.getMonth() + 1}`.padStart(2, '0');
    const day = `${d.getDate()}`.padStart(2, '0');
    return `${y}-${m}-${day}`;
  }

  private toTimeString(d: Date): string {
    const h = `${d.getHours()}`.padStart(2, '0');
    const m = `${d.getMinutes()}`.padStart(2, '0');
    const s = `${d.getSeconds()}`.padStart(2, '0');
    return `${h}:${m}:${s}`;
  }
}
