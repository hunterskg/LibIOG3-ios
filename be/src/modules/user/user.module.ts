import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './domain/entities/user.entity';
import { UserService } from './application/services/user.service';
import { ReaderController } from './infra/controllers/reader.controller';
import { StaffController } from './infra/controllers/staff.controller';

@Module({
  imports: [TypeOrmModule.forFeature([User])],
  controllers: [ReaderController, StaffController],
  providers: [UserService],
  exports: [UserService, TypeOrmModule],
})
export class UserModule {}
