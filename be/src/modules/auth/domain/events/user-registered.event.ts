import { DomainEvent } from '../../../../common/domain/domain-event';

export class UserRegisteredEvent extends DomainEvent {
  static readonly EVENT_NAME = 'user.registered';

  constructor(
    public readonly email: string,
    public readonly displayName: string,
    public readonly code: string,
    public readonly expiresInSeconds: number,
  ) {
    super();
  }

  getEventName(): string {
    return UserRegisteredEvent.EVENT_NAME;
  }
}
