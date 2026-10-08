import { Global, Module } from '@nestjs/common';
import { DatabaseModule } from './database/database.module';
import { QueueModule } from './queue/queue.module';
import { EventModule } from './event/event.module';
import { CacheModule } from './cache/cache.module';
import { MailModule } from './mail/mail.module';

@Global()
@Module({
  imports: [DatabaseModule, QueueModule, EventModule, CacheModule, MailModule],
  exports: [DatabaseModule, QueueModule, EventModule, CacheModule, MailModule],
})
export class InfrastructureModule {}
