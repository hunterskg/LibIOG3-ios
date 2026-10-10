import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Reader } from '../../../user/domain/entities/reader.entity';
import { Staff } from '../../../user/domain/entities/staff.entity';
import { DeviceAssignment } from '../../../device/domain/entities/device-assignment.entity';
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

  @ManyToOne(() => Reader, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'reader_id' })
  reader!: Reader;

  @Column({ name: 'gate_id', type: 'uuid', nullable: true })
  gateId?: string;

  @ManyToOne(() => Gate, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'gate_id' })
  gate?: Gate;

  @Column({ name: 'assignment_id', type: 'uuid', nullable: true })
  assignmentId?: string;

  @ManyToOne(() => DeviceAssignment, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'assignment_id' })
  assignment?: DeviceAssignment;

  @Column({ name: 'staff_id', type: 'uuid', nullable: true })
  staffId?: string;

  @ManyToOne(() => Staff, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'staff_id' })
  staff?: Staff;

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
