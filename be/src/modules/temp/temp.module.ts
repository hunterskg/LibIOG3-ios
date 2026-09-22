import { Module } from '@nestjs/common';
import { TempController } from './controller/temp.controller';
import { TempService } from './services/temp.service';

@Module({
  controllers: [TempController],
  providers: [TempService],
  exports: [TempService],
})
export class TempModule {}
