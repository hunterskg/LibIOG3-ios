import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { BiometricStatus } from '../enums/biometric-status.enum';
import { User } from '../../../user/domain/entities/user.entity';

@Entity('biometric_profiles')
export class BiometricProfile {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'reader_id', type: 'uuid' })
  readerId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'reader_id' })
  reader?: User;

  @Column({ name: 'provider_reference' })
  providerReference!: string;

  @Column({ name: 'consent_given', type: 'boolean', default: false })
  consentGiven!: boolean;

  @Column({ name: 'consent_at', type: 'timestamp' })
  consentAt!: Date;

  @Column({
    type: 'enum',
    enum: BiometricStatus,
    default: BiometricStatus.PENDING,
  })
  status!: BiometricStatus;

  @Column({ name: 'consent_revoked_at', type: 'timestamp', nullable: true })
  consentRevokedAt?: Date | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;

  static create(
    readerId: string,
    providerReference: string,
    consentGiven: boolean,
    consentAt: Date,
    status: BiometricStatus,
    consentRevokedAt?: Date | null,
  ): BiometricProfile {
    const profile = new BiometricProfile();
    profile.readerId = readerId;
    profile.providerReference = providerReference;
    profile.consentGiven = consentGiven;
    profile.consentAt = consentAt;
    profile.status = status;
    profile.consentRevokedAt = consentRevokedAt;
    return profile;
  }

  revoke(): void {
    this.consentGiven = false;
    this.consentRevokedAt = new Date();
    this.status = BiometricStatus.INACTIVE;
  }

  isActive(): boolean {
    return this.status === BiometricStatus.ACTIVE && this.consentGiven;
  }
}
