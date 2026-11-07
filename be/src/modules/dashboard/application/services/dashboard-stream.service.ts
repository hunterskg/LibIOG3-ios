import { Injectable } from '@nestjs/common';
import { Observable, Subject } from 'rxjs';

@Injectable()
export class DashboardStreamService {
  private readonly readerAccessEvents = new Subject<MessageEvent>();

  getReaderAccessEvents(): Observable<MessageEvent> {
    return this.readerAccessEvents.asObservable();
  }

  publishReaderAccessEvent(event: MessageEvent): void {
    this.readerAccessEvents.next(event);
  }
}
