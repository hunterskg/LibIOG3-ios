import { FaceDomainException } from './face-domain.exception';

export class EmbeddingMismatchException extends FaceDomainException {
  constructor(message = 'Embedding mismatch') {
    super(message);
    this.name = 'EmbeddingMismatchException';
  }
}
