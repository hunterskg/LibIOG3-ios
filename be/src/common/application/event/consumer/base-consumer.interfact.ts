import { Logger } from '@nestjs/common';

export abstract class BaseConsumer<M> {
  protected readonly logger: Logger;

  protected constructor(context: string) {
    this.logger = new Logger(context);
  }

  abstract consumeMessage(message: M): Promise<void> | void;
}
