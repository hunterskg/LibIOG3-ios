import { DomainEvent } from '../../../../common/domain/domain-event';
import { AccessAction } from '../../../access/domain/enums/access-action.enum';

export class ReaderAccessEvent extends DomainEvent {
  static readonly EVENT_NAME = 'reader.access';

  constructor(
    public readonly action: AccessAction,
    public readonly readerId: string,
    public readonly deviceId: string,
    public readonly accessLogId: string,
    public readonly occurredAt: Date,
  ) {
    super();
  }

  getEventName(): string {
    return ReaderAccessEvent.EVENT_NAME;
  }
}
