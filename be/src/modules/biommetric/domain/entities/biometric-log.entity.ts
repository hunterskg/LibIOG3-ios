import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Reader } from '../../../user/domain/entities/reader.entity';
import { DeviceAssignment } from '../../../device/domain/entities/device-assignment.entity';

@Entity('biometric_logs')
export class BiometricLog {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'assignment_id', type: 'uuid', nullable: true })
  assignmentId?: string;

  @ManyToOne(() => DeviceAssignment, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'assignment_id' })
  assignment?: DeviceAssignment;

  @Column({ name: 'reader_id', type: 'uuid', nullable: true })
  readerId?: string;

  @ManyToOne(() => Reader, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'reader_id' })
  reader?: Reader;

  @Column()
  action!: string;

  @Column({ default: false })
  matched!: boolean;

  @Column({ name: 'occurred_at', type: 'timestamp' })
  occurredAt!: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;
}
