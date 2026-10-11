import { randomUUID } from 'crypto';
import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { BiometricProfile } from '../../../domain/entities/biometric-profile.entity';

@Entity('face_profiles')
export class FaceProfile {
  @PrimaryGeneratedColumn('uuid', { name: 'face_profile_id' })
  faceProfileId!: string;

  @Column({
    type: 'vector',
    length: 512,
    transformer: {
      to: (value: number[]) => (value ? JSON.stringify(value) : value),
      from: (value: string | number[]): number[] =>
        typeof value === 'string' ? (JSON.parse(value) as number[]) : value,
    },
  })
  embedding!: number[];

  @Column({ name: 'biometric_profile_id', type: 'uuid' })
  biometricProfileId!: string;

  @ManyToOne(() => BiometricProfile, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'biometric_profile_id' })
  biometricProfile?: BiometricProfile;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;

  static create(
    faceProfileId: string | undefined,
    embedding: number[],
    biometricProfileId: string,
    biometricProfile?: BiometricProfile,
  ): FaceProfile {
    const faceProfile = new FaceProfile();
    faceProfile.faceProfileId = faceProfileId || randomUUID();
    faceProfile.embedding = embedding;
    faceProfile.biometricProfileId = biometricProfileId;
    if (biometricProfile) {
      faceProfile.biometricProfile = biometricProfile;
    }
    return faceProfile;
  }
}
