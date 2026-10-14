import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Role } from '../enums/role.enum';
import { UserStatus } from '../enums/user-statis.enum';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ unique: true })
  email!: string;

  @Column({ name: 'full_name', length: 255 })
  fullName!: string;

  @Column({ name: 'password_hash' })
  passwordHash!: string;

  @Column({ type: 'enum', enum: Role, default: Role.READER })
  role!: Role;

  @Column({ type: 'enum', enum: UserStatus, default: UserStatus.ACTIVE })
  status!: UserStatus;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;

  static create(
    email: string,
    fullName: string,
    passwordHash: string,
    role = Role.READER,
  ): User {
    const user = new User();
    user.email = email;
    user.fullName = fullName;
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
