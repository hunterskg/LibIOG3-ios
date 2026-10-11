import { FaceDomainException } from './face-domain.exception';

export class LowFaceQualityException extends FaceDomainException {
  constructor(message = 'Face quality too low') {
    super(message);
    this.name = 'LowFaceQualityException';
  }
}
