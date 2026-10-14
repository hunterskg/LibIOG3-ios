
import {
    Column,
    CreateDateColumn,
    Entity,
    JoinColumn,
    ManyToOne,
    PrimaryGeneratedColumn,
} from 'typeorm';

import { Reader } from '../../../user/domain/entities/reader.entity';
import { QrTokenStatus } from '../enums/qr-token-status.enum';

@Entity('qr_tokens')
export class QrToken {
    @PrimaryGeneratedColumn('uuid')
    id!: string;

    @ManyToOne(() => Reader, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'reader_id' })
    reader!: Reader;

    @Column({ name: 'token_hash', type: 'text', unique: true })
    tokenHash!: string;

    @Column({ name: 'expires_at', type: 'timestamptz' })
    expiresAt!: Date;

    @Column({
        name: 'used_at',
        type: 'timestamptz',
        nullable: true,
    })
    usedAt?: Date | null;

    @Column({
        name: 'revoked_at',
        type: 'timestamptz',
        nullable: true,
    })
    revokedAt?: Date | null;


    @Column({
        name: 'status',
        type: 'enum',
        enum: QrTokenStatus,
        default: QrTokenStatus.ACTIVE,
    })
    status!: QrTokenStatus;


    @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
    createdAt!: Date;
}