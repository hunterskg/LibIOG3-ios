import { Module } from '@nestjs/common';
import { BullmqModule } from './bullmq/bullmq.module';
import {
  QUEUE_SERVICE,
  QueueService,
  QueueJobOptions,
} from './application/queue-service.interface';

export { QUEUE_SERVICE, QueueService, QueueJobOptions };

@Module({
  imports: [BullmqModule],
  exports: [BullmqModule],
})
export class QueueModule {}
