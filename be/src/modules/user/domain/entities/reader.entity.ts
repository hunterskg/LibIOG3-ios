import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { UserAuth } from '../entities/user-auth.entity';

// ponytail: string status thay vì enum, nâng cấp khi chốt danh sách trạng thái
@Entity('readers')
export class Reader extends UserAuth {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: 'full_name' })
  fullName!: string;

  @Column({ nullable: true })
  phone?: string;

  @Column({ name: 'date_of_birth', type: 'date', nullable: true })
  dateOfBirth?: Date;

  @Column({ default: 'active' })
  status!: string;

  @CreateDateColumn({ name: 'registered_at' })
  registeredAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;
}
