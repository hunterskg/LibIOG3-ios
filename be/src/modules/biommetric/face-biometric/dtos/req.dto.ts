import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';
import { IdempotentReq } from '../../../../common/dtos/req.dto';
import { FacePoseStatus } from '../domain/enums/face-pose-status.enum';

export class BoundingBoxReq {
  @ApiProperty({ description: 'Tọa độ X góc trên bên trái', example: 0.1 })
  @IsNumber()
  x!: number;

  @ApiProperty({ description: 'Tọa độ Y góc trên bên trái', example: 0.1 })
  @IsNumber()
  y!: number;

  @ApiProperty({ description: 'Chiều rộng', example: 0.3 })
  @IsNumber()
  width!: number;

  @ApiProperty({ description: 'Chiều cao', example: 0.4 })
  @IsNumber()
  height!: number;

  @ApiPropertyOptional({
    description: 'Độ tin cậy của bounding box',
    example: 0.95,
  })
  @IsNumber()
  @IsOptional()
  confidence?: number;
}

export class Point2DReq {
  @ApiProperty({ description: 'Tọa độ X', example: 0.25 })
  @IsNumber()
  x!: number;

  @ApiProperty({ description: 'Tọa độ Y', example: 0.35 })
  @IsNumber()
  y!: number;

  @ApiPropertyOptional({ description: 'Chỉ số landmark', example: 0 })
  @IsNumber()
  @IsOptional()
  index?: number;
}

export class DetectFaceReq {
  @ApiProperty({ description: 'Chuỗi Base64 của ảnh khuôn mặt' })
  @IsString()
  @IsNotEmpty({ message: 'Ảnh không được để trống' })
  imageBase64!: string;

  @ApiPropertyOptional({
    description: 'Số lượng khuôn mặt tối đa',
    example: 1,
    default: 1,
  })
  @IsNumber()
  @IsOptional()
  maxFaces?: number;
}

export class CheckLivenessReq {
  @ApiProperty({ description: 'Chuỗi Base64 của ảnh kiểm tra liveness' })
  @IsString()
  @IsNotEmpty({ message: 'Ảnh không được để trống' })
  imageBase64!: string;
}

export class ExtractEmbeddingReq {
  @ApiProperty({ description: 'Chuỗi Base64 của ảnh' })
  @IsString()
  @IsNotEmpty({ message: 'Ảnh không được để trống' })
  imageBase64!: string;

  @ApiPropertyOptional({ type: () => BoundingBoxReq })
  @ValidateNested()
  @Type(() => BoundingBoxReq)
  @IsOptional()
  bbox?: BoundingBoxReq;

  @ApiPropertyOptional({ type: () => [Point2DReq] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => Point2DReq)
  @IsOptional()
  landmarks?: Point2DReq[];
}

export class VerifyFaceReq {
  @ApiProperty({
    description: 'Chuỗi Base64 của ảnh cần xác thực',
  })
  @IsString()
  @IsNotEmpty({ message: 'Ảnh không được để trống' })
  imageBase64!: string;

  @ApiProperty({
    description: 'Embedding vector mẫu để so khớp',
    type: [Number],
  })
  @IsArray()
  @IsNumber({}, { each: true })
  referenceEmbedding!: number[];

  @ApiPropertyOptional({ type: () => BoundingBoxReq })
  @ValidateNested()
  @Type(() => BoundingBoxReq)
  @IsOptional()
  bbox?: BoundingBoxReq;

  @ApiPropertyOptional({
    description: 'Ngưỡng tương đồng',
    example: 0.68,
    default: 0.68,
  })
  @IsNumber()
  @IsOptional()
  threshold?: number;
}

export class RegisterFaceReq extends IdempotentReq {
  @ApiProperty({ description: 'Mã định danh bạn đọc', example: 'reader-123' })
  @IsString()
  @IsNotEmpty({ message: 'Mã định danh bạn đọc không được để trống' })
  readerId!: string;

  @ApiProperty({ description: 'Trạng thái pose khuôn mặt', example: 'FRONTAL' })
  @IsString()
  @IsNotEmpty({ message: 'Trạng thái dáng khuôn mặt không được để trống' })
  facePose!: FacePoseStatus;

  static of(
    readerId: string,
    requestId: string,
    facePose: FacePoseStatus,
  ): RegisterFaceReq {
    const req = new RegisterFaceReq();
    req.readerId = readerId;
    req.requestId = requestId;
    req.facePose = facePose;
    return req;
  }
}
