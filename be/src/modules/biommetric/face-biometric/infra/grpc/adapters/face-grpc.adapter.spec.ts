import {
  BadRequestException,
  HttpException,
  InternalServerErrorException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { mapFaceGrpcError } from './face-grpc.adapter';

describe('mapFaceGrpcError', () => {
  it.each([
    [3, BadRequestException],
    [9, UnprocessableEntityException],
    [5, UnprocessableEntityException],
    [7, UnprocessableEntityException],
    [14, InternalServerErrorException],
    [4, InternalServerErrorException],
    [13, InternalServerErrorException],
    [123, InternalServerErrorException],
  ])('maps gRPC code %i to HTTP exception', (code, ExceptionType) => {
    expect(mapFaceGrpcError({ code, details: 'face error' })).toBeInstanceOf(
      ExceptionType,
    );
  });

  it('prefers details and uses a safe fallback when details are empty', () => {
    expect(
      mapFaceGrpcError({ code: 9, details: '  ', message: 'message' }),
    ).toEqual(
      expect.objectContaining({ message: expect.stringContaining('message') }),
    );
    expect(mapFaceGrpcError({ code: 9 }).message).toBe(
      'Ảnh khuôn mặt không đáp ứng yêu cầu.',
    );
  });

  it('preserves existing HTTP exceptions', () => {
    const error = new HttpException('existing', 401);
    expect(mapFaceGrpcError(error)).toBe(error);
  });

  it('does not expose transport details for server errors', () => {
    expect(mapFaceGrpcError({ code: 14, details: 'private detail' })).toEqual(
      expect.objectContaining({
        message: expect.not.stringContaining('private detail'),
      }),
    );
  });
});
