export class FaceDomainException extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'FaceDomainException';
  }
}
