import { InfrastructureModule } from './modules/infra/infrastructure.module';
import { TempModule } from './modules/temp/temp.module';
import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';

@Module({
  imports: [InfrastructureModule, TempModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
