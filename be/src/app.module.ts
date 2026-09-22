import { TempModule } from './modules/temp/temp.module';
import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';

@Module({
  imports: [TempModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
