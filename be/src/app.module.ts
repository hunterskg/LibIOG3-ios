import { AuthModule } from './modules/auth/auth.module';
import { UserModule } from './modules/user/user.module';
import { InfrastructureModule } from './modules/infra/infrastructure.module';
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    AuthModule,
    InfrastructureModule,
    UserModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
