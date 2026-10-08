import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './domain/entities/user.entity';
import { Reader } from './domain/entities/reader.entity';
import { Staff } from './domain/entities/staff.entity';
import { UserService } from './application/services/user.service';
import { ReaderService } from './application/services/reader.service';
import { StaffService } from './application/services/staff.service';
import { ReaderController } from './infra/controllers/reader.controller';
import { StaffController } from './infra/controllers/staff.controller';

@Module({
  imports: [TypeOrmModule.forFeature([User, Reader, Staff])],
  controllers: [ReaderController, StaffController],
  providers: [UserService, ReaderService, StaffService],
  exports: [UserService, ReaderService, StaffService],
})
export class UserModule {}
