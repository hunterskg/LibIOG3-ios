import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from '../../../user/domain/entities/user.entity';
import { Device } from '../../../device/domain/entities/device.entity';
import { Gate } from '../../../device/domain/entities/gate.entity';
import { AccessAction } from '../enums/access-action.enum';
import { AccessMethod } from '../enums/access-method.enum';
import { AccessResult } from '../enums/access-result.enum';

@Entity('access_logs')
export class AccessLog {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'reader_id', type: 'uuid' })
  readerId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'reader_id' })
  reader!: User;

  @Column({ name: 'gate_id', type: 'uuid', nullable: true })
  gateId?: string;

  @ManyToOne(() => Gate, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'gate_id' })
  gate?: Gate;

  @Column({ name: 'device_id', type: 'uuid' })
  deviceId!: string;

  @ManyToOne(() => Device, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'device_id' })
  device!: Device;

  @Column({ name: 'staff_id', type: 'uuid', nullable: true })
  staffId?: string;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'staff_id' })
  staff?: User;

  @Column({ type: 'enum', enum: AccessAction })
  action!: AccessAction;

  @Column({ type: 'enum', enum: AccessMethod })
  method!: AccessMethod;

  @Column({ type: 'enum', enum: AccessResult })
  result!: AccessResult;

  @Column({ nullable: true })
  reason?: string;

  @Column({ name: 'occurred_at', type: 'timestamp' })
  occurredAt!: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;
}
