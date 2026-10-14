import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from '../../../user/domain/entities/user.entity';
import { Gate } from './gate.entity';
import { DeviceStatus } from '../enums/device-status.enum';

@Entity('devices')
export class Device {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'staff_id', type: 'uuid' })
  staffId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'staff_id' })
  staff!: User;

  @Column({ name: 'gate_id', type: 'uuid' })
  gateId!: string;

  @ManyToOne(() => Gate, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'gate_id' })
  gate!: Gate;

  @Column({ name: 'activation_code', type: 'varchar', length: 100 })
  activationCode!: string;

  @Column({ name: 'device_fingerprint', type: 'text', nullable: true })
  deviceFingerprint?: string | null;

  @Column({ name: 'device_name', type: 'varchar', length: 255 })
  deviceName!: string;

  @Column({
    name: 'device_platform',
    type: 'varchar',
    length: 100,
    nullable: true,
  })
  devicePlatform?: string | null;

  @Column({
    type: 'enum',
    enum: DeviceStatus,
    default: DeviceStatus.PENDING,
  })
  status!: DeviceStatus;

  @Column({ name: 'assigned_by', type: 'uuid' })
  assignedById!: string;

  @ManyToOne(() => User, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'assigned_by' })
  assignedBy!: User;

  @Column({
    name: 'assigned_at',
    type: 'timestamp',
    default: () => 'CURRENT_TIMESTAMP',
  })
  assignedAt!: Date;

  @Column({ name: 'revoked_at', type: 'timestamp', nullable: true })
  revokedAt?: Date | null;

  @Column({ name: 'activated_at', type: 'timestamp', nullable: true })
  activatedAt?: Date | null;

  @Column({ name: 'expired_at', type: 'timestamp', nullable: true })
  expiredAt?: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
