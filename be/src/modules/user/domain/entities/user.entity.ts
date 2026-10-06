import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToOne,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Role } from '../enums/role.enum';
import { UserStatus } from '../enums/user-statis.enum';
import { Reader } from './reader.entity';
import { Staff } from './staff.entity';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ unique: true })
  email!: string;

  @Column({ name: 'password_hash' })
  passwordHash!: string;

  @Column({ type: 'enum', enum: Role, default: Role.READER })
  role!: Role;

  @Column({ type: 'enum', enum: UserStatus, default: UserStatus.ACTIVE })
  status!: UserStatus;

  @OneToOne(() => Reader, (reader) => reader.user)
  reader?: Reader;

  @OneToOne(() => Staff, (staff) => staff.user)
  staff?: Staff;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;

  static create(email: string, passwordHash: string, role = Role.READER): User {
    const user = new User();
    user.email = email;
    user.passwordHash = passwordHash;
    user.role = role;
    user.status = UserStatus.ACTIVE;
    return user;
  }

  isMatchingPassword(passwordHash: string): boolean {
    return this.passwordHash === passwordHash;
  }

  isActived(): boolean {
    return this.status === UserStatus.ACTIVE;
  }

  updatePassword(passwordHash: string): void {
    this.passwordHash = passwordHash;
  }
}
