import { FaceDomainException } from './face-domain.exception';

export class SpoofDetectedException extends FaceDomainException {
  constructor(message = 'Spoof detected') {
    super(message);
    this.name = 'SpoofDetectedException';
  }
}
