import { QrToken } from '../../domain/entities/qr-token.entity';
import { QrTokenStatus } from '../../domain/enums/qr-token-status.enum';
import { Reader } from '../../../user/domain/entities/reader.entity';
import { User } from '../../../user/domain/entities/user.entity';
import { Role } from '../../../user/domain/enums/role.enum';
import { Injectable,UnauthorizedException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { randomBytes, createHash } from 'crypto';

@Injectable()
export class QrService{
    constructor(
        @InjectRepository(QrToken)
        private readonly qrTokenRepo: Repository<QrToken>,
        
        @InjectRepository(Reader)
        private readonly readerRepo: Repository<Reader>,

        @InjectRepository(User)
        private readonly userRepo: Repository<User>,
    ){}

    async createQrToken(userId:string){
        const user = await this.userRepo.findOne({
            where:{id:userId},
        });

        if(!user){
            throw new Error('User not found');
        }

        if(user.role !== Role.READER || user.status !== 'active'){
            throw new Error('Only active readers can create QR tokens');
        }

        const reader = await this.readerRepo.findOne({
            where:{user:{id:userId}},
        });

        if(!reader){
            throw new Error('Reader not found');
        }

        const token = randomBytes(32).toString('hex');


        const tokenHash = createHash('sha256').update(token).digest('hex');


        const qrToken = this.qrTokenRepo.create({
            reader: reader,
            tokenHash: tokenHash,
            expiresAt: new Date(Date.now() +  30 * 1000), 
            status: QrTokenStatus.ACTIVE,
        });

        await this.qrTokenRepo.save(qrToken);

        return {token,expiresAt: qrToken.expiresAt};
    }



    async verifyAndConsumeQrToken(token:string){
        if(!token || !/^[a-f0-9]{64}$/i.test(token)){
            throw new UnauthorizedException('Invalid QR token');

        }


        const tokenHash = createHash('sha256').update(token).digest('hex');

        const qrToken = await this.qrTokenRepo.findOne({
            where:{
                tokenHash: tokenHash,
                status:QrTokenStatus.ACTIVE,
            },
            relations:{
                reader:true,
            },
        });
        
        const now = new Date();
        if(!qrToken || qrToken.expiresAt <= now||qrToken.revokedAt){
            throw new UnauthorizedException('Invalid or expired QR token');
        }


        const result = await this.qrTokenRepo.createQueryBuilder()
            .update(QrToken)
            .set({
                status:QrTokenStatus.USED,
                usedAt:now,
            }).where(
                'id=:id AND status = :active AND expires_at>:now AND revoked_at IS NULL',
                {
                    id:qrToken.id,
                    active:QrTokenStatus.ACTIVE,
                    now:now,
                },
            ).execute();

            if (result.affected !== 1){
                throw new UnauthorizedException('QR token has already been used or expired');
            }
            return {
                valid:true,
                readerId:qrToken.reader.id,
                scannedAt:now,
            }
    }
}


