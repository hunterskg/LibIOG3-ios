import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { QrToken } from './domain/entities/qr-token.entity';
import { User } from '../user/domain/entities/user.entity';
import { QrService } from './application/services/qr.service';
import { QrController } from './infra/controllers/qr.controller';

@Module({
  imports: [TypeOrmModule.forFeature([QrToken, User])],
  controllers: [QrController],
  providers: [QrService],
  exports: [QrService],
})
export class QrModule {}
