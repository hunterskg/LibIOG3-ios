import {
  BadRequestException,
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
  UnprocessableEntityException,
} from '@nestjs/common';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { EmbeddingMismatchException } from '../../domain/exceptions/embedding-mismatch.exception';
import { FaceDomainException } from '../../domain/exceptions/face-domain.exception';
import { FaceNotFoundException } from '../../domain/exceptions/face-not-found.exception';
import { LowFaceQualityException } from '../../domain/exceptions/low-face-quality.exception';
import { MultipleFacesDetectedException } from '../../domain/exceptions/multiple-faces-detected.exception';
import { SpoofDetectedException } from '../../domain/exceptions/spoof-detected.exception';

@Injectable()
export class FaceDomainExceptionInterceptor implements NestInterceptor {
  intercept(_context: ExecutionContext, next: CallHandler): Observable<any> {
    return next.handle().pipe(
      catchError((error: unknown) => {
        if (error instanceof FaceNotFoundException) {
          return throwError(
            () => new UnprocessableEntityException(error.message),
          );
        }
        if (error instanceof MultipleFacesDetectedException) {
          return throwError(
            () => new UnprocessableEntityException(error.message),
          );
        }
        if (error instanceof LowFaceQualityException) {
          return throwError(
            () => new UnprocessableEntityException(error.message),
          );
        }
        if (error instanceof SpoofDetectedException) {
          return throwError(
            () => new UnprocessableEntityException(error.message),
          );
        }
        if (error instanceof EmbeddingMismatchException) {
          return throwError(() => new BadRequestException(error.message));
        }
        if (error instanceof FaceDomainException) {
          return throwError(() => new BadRequestException(error.message));
        }
        return throwError(() => error);
      }),
    );
  }
}
