import { Injectable } from '@nestjs/common';
import { EventHandler } from '../../../../common/application/event/event-handler.interface';
import { ReaderAccessEvent } from '../../../checkin-out/domain/events/reader-access.event';
import { DashboardStreamService } from '../services/dashboard-stream.service';

@Injectable()
export class ReaderAccessHandler implements EventHandler<ReaderAccessEvent> {
  constructor(
    private readonly dashboardStreamService: DashboardStreamService,
  ) {}

  handle(data: ReaderAccessEvent): Promise<void> {
    this.dashboardStreamService.publishReaderAccessEvent(
      new MessageEvent('reader.access', {
        data: JSON.stringify({
          action: data.action,
          readerId: data.readerId,
          deviceId: data.deviceId,
          accessLogId: data.accessLogId,
          occurredAt: data.occurredAt,
        }),
      }),
    );
    return Promise.resolve();
  }
}
