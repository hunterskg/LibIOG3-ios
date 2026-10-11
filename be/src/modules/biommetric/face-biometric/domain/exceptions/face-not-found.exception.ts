import { FaceDomainException } from './face-domain.exception';

export class FaceNotFoundException extends FaceDomainException {
  constructor(message = 'Face not found') {
    super(message);
    this.name = 'FaceNotFoundException';
  }
}
