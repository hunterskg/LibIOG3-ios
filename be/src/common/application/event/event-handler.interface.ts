import { DomainEvent } from '../../domain/domain-event';
import { Handler } from '../handler';

export interface EventHandler<T extends DomainEvent> extends Handler<T> {}
