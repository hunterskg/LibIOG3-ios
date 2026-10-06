import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity('refresh_tokens')
export class RefreshToken {
  @PrimaryGeneratedColumn('uuid')
  token!: string;

  @Column({ name: 'user_id' })
  userId!: string;

  @Column({ name: 'expires_at', type: 'timestamp' })
  expiresAt!: Date;

  @Column({ name: 'is_revoked', default: false })
  isRevoked!: boolean;

  @Column({ name: 'revoked_at', type: 'timestamp', nullable: true })
  revokedAt!: Date | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  static create(userId: string, expiresAt: Date): RefreshToken {
    const refreshToken = new RefreshToken();
    refreshToken.userId = userId;
    refreshToken.expiresAt = expiresAt;
    refreshToken.isRevoked = false;
    refreshToken.revokedAt = null;
    refreshToken.createdAt = new Date();
    return refreshToken;
  }

  revoke(): void {
    if (this.isRevoked) return;
    this.isRevoked = true;
    this.revokedAt = new Date();
  }

  isExpired(): boolean {
    return new Date() > this.expiresAt;
  }

  isValid(): boolean {
    return !this.isRevoked && !this.isExpired();
  }
}
