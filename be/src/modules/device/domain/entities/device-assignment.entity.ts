import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from '../../../user/domain/entities/user.entity';
import { Staff } from '../../../user/domain/entities/staff.entity';
import { AssignmentStatus } from '../enums/assignment-status.enum';

@Entity('device_assignments')
export class DeviceAssignment {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'staff_id', type: 'uuid' })
  staffId!: string;

  @ManyToOne(() => Staff, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'staff_id' })
  staff!: Staff;

  @Column({ name: 'activation_code', length: 6 })
  activationCode!: string;

  @Column({ name: 'device_fingerprint', nullable: true })
  deviceFingerprint?: string;

  @Column({ name: 'device_name', nullable: true })
  deviceName?: string;

  @Column({ name: 'device_platform', nullable: true })
  devicePlatform?: string;

  @Column({
    type: 'enum',
    enum: AssignmentStatus,
    default: AssignmentStatus.PENDING,
  })
  status!: AssignmentStatus;

  @Column({ name: 'assigned_by', type: 'uuid' })
  assignedById!: string;

  @ManyToOne(() => User, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'assigned_by' })
  assignedBy!: User;

  @Column({ name: 'activated_at', type: 'timestamp', nullable: true })
  activatedAt?: Date;

  @Column({ name: 'revoked_at', type: 'timestamp', nullable: true })
  revokedAt?: Date;

  @Column({ name: 'expires_at', type: 'timestamp' })
  expiresAt!: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;
}
