export abstract class DomainEvent {
  readonly occuredOn: Date;

  static readonly EVENT_NAME: string;

  constructor() {
    this.occuredOn = new Date();
  }

  abstract getEventName(): string;

  serialize(): string {
    return JSON.stringify(this);
  }

  static deserialize<T extends DomainEvent>(
    this: new (...args: any[]) => T,
    json: string,
  ): T {
    const data = typeof json === 'string' ? (JSON.parse(json) as T) : json;
    const instance = Object.create(this.prototype as object) as T;
    return Object.assign(instance, data, {
      occuredOn: data?.occuredOn ? new Date(data.occuredOn) : new Date(),
    });
  }
}
