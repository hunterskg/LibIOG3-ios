import {
  BadRequestException,
  HttpException,
  InternalServerErrorException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { mapFaceGrpcError } from './face-grpc.adapter';

describe('mapFaceGrpcError', () => {
  it.each([
    [3, BadRequestException, 'Bad input'],
    [9, UnprocessableEntityException, 'Multiple faces'],
    [5, UnprocessableEntityException, 'Face missing'],
    [7, UnprocessableEntityException, 'Spoof detected'],
  ])('maps gRPC code %s to HTTP 4xx and keeps details', (code, type, details) => {
    const mapped = mapFaceGrpcError({ code, details });
    expect(mapped).toBeInstanceOf(type);
    expect((mapped as HttpException).getResponse()).toMatchObject({ message: details });
  });

  it('uses message then safe fallback when details are absent or empty', () => {
    expect((mapFaceGrpcError({ code: 9, details: '', message: 'Message' }) as HttpException).getResponse())
      .toMatchObject({ message: 'Message' });
    expect((mapFaceGrpcError({ code: 9 }) as HttpException).getResponse())
      .toMatchObject({ message: 'Ảnh khuôn mặt không đáp ứng yêu cầu.' });
  });

  it.each([4, 13, 14, 99, undefined])('keeps server/unknown code %s as HTTP 500', (code) => {
    expect(mapFaceGrpcError({ code })).toBeInstanceOf(InternalServerErrorException);
  });

  it('preserves an existing HttpException instance', () => {
    const original = new BadRequestException('Already HTTP');
    expect(mapFaceGrpcError(original)).toBe(original);
  });
});
