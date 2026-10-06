import { AuthModule } from './modules/auth/auth.module';
import { UserModule } from './modules/user/user.module';
import { InfrastructureModule } from './modules/infra/infrastructure.module';
import { TempModule } from './modules/temp/temp.module';
import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';

@Module({
  imports: [AuthModule, InfrastructureModule, TempModule, UserModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
