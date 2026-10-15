import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
} from 'typeorm';

import { ScheduleType } from '../enums/schedule-type.enum';

@Entity('library_schedules')
export class LibrarySchedule {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({
    name: 'type',
    type: 'enum',
    enum: ScheduleType,
  })
  type!: ScheduleType;

  // Dùng cho type = WEEKLY: 0 = Chủ nhật ... 6 = Thứ Bảy (khớp Date.getDay()).
  @Column({ name: 'day_of_week', type: 'int', nullable: true })
  dayOfWeek?: number | null;

  // Dùng cho type = SPECIAL: ngày cụ thể bị ghi đè (lễ, Tết...).
  @Column({ name: 'specific_date', type: 'date', nullable: true })
  specificDate?: string | null;

  @Column({ name: 'open_time', type: 'time', nullable: true })
  openTime?: string | null;

  @Column({ name: 'close_time', type: 'time', nullable: true })
  closeTime?: string | null;

  // true = đóng cả ngày, bỏ qua open_time/close_time.
  @Column({ name: 'is_closed', type: 'boolean', default: false })
  isClosed!: boolean;

  @Column({ name: 'note', type: 'text', nullable: true })
  note?: string | null;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive!: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
