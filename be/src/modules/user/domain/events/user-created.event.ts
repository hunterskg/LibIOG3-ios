import { DomainEvent } from '../../../../common/domain/domain-event';

export class UserCreatedEvent extends DomainEvent {
  static readonly EVENT_NAME = 'user.created';

  constructor(
    public readonly userId: string,
    public readonly email: string,
    public readonly displayName: string,
    public readonly userName: string,
  ) {
    super();
  }

  getEventName(): string {
    return UserCreatedEvent.EVENT_NAME;
  }
}
