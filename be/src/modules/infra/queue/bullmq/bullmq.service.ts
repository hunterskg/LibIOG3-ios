/*
https://docs.nestjs.com/providers#services
*/

import { Injectable, OnModuleDestroy } from '@nestjs/common';
import {
  QueueJobOptions,
  QueueService,
} from '../application/queue-service.interface';
import { Handler } from '../../../../common/application/handler';
import { Queue, Worker } from 'bullmq';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class BullmqService implements QueueService, OnModuleDestroy {
  private readonly queues = new Map<string, Queue>();
  private readonly workers = new Map<string, Worker>();

  constructor(private config: ConfigService) {}

  private getRedisOpts() {
    return {
      host: this.config.get<string>('REDIS_HOST', 'localhost'),
      port: this.config.get<number>('REDIS_PORT', 6379),
      password: this.config.get<string>('REDIS_PASSWORD') || undefined,
    };
  }

  private getQueue(name: string): Queue {
    let queue = this.queues.get(name);
    if (!queue) {
      queue = new Queue(name, { connection: this.getRedisOpts() });
      this.queues.set(name, queue);
    }
    return queue;
  }

  async publish<T>(
    queueName: string,
    data: T,
    options?: QueueJobOptions,
  ): Promise<void> {
    const queue = this.getQueue(queueName);
    await queue.add('default', data, {
      attempts: options?.attempts,
    });
  }

  async consume<T>(queueName: string, handler: Handler<T>): Promise<void> {
    if (this.workers.has(queueName)) return;

    const worker = new Worker(
      queueName,
      async (job) => {
        await handler.handle(job.data as T);
      },
      { connection: this.getRedisOpts() },
    );

    this.workers.set(queueName, worker);
  }

  async onModuleDestroy(): Promise<void> {
    const closeWorkers = [...this.workers.values()].map((w) => w.close());
    const closeQueues = [...this.queues.values()].map((q) => q.close());
    await Promise.all([...closeWorkers, ...closeQueues]);
    this.workers.clear();
    this.queues.clear();
  }
}
