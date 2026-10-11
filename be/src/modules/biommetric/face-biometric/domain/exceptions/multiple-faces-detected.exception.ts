import { FaceDomainException } from './face-domain.exception';

export class MultipleFacesDetectedException extends FaceDomainException {
  constructor(message = 'Multiple faces detected') {
    super(message);
    this.name = 'MultipleFacesDetectedException';
  }
}
