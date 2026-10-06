import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './domain/entities/user.entity';
import { Reader } from './domain/entities/reader.entity';
import { Staff } from './domain/entities/staff.entity';
import { UserService } from './application/services/user.service';

@Module({
  imports: [TypeOrmModule.forFeature([User, Reader, Staff])],
  controllers: [],
  providers: [UserService],
  exports: [UserService],
})
export class UserModule {}
