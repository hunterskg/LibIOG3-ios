import {
  BadRequestException,
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { JwtGuard } from '../../../../auth/infra/guard/jwt.guard';
import { CurrentUser } from '../../../../auth/infra/decorators/current-user.decorator';
import { FaceBiometricService } from '../../application/services/facebiometric.service';
import { RegisterFaceReq } from '../../dtos/req.dto';
import { RegisterFaceRes } from '../../dtos/res.dto';
import { FaceDomainExceptionInterceptor } from '../interceptors/face-domain-exception.interceptor';
import { FacePoseStatus } from '../../domain/enums/face-pose-status.enum';

interface UploadedFile {
  buffer: Buffer;
  originalname?: string;
  mimetype?: string;
  size?: number;
}

@ApiTags('Biometric Face')
@ApiBearerAuth('access-token')
@UseGuards(JwtGuard)
@UseInterceptors(FaceDomainExceptionInterceptor)
@Controller('biometric/face')
export class FaceBiometricController {
  constructor(private readonly faceBiometricService: FaceBiometricService) {}

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Đăng ký khuôn mặt bạn đọc' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        image: {
          type: 'string',
          format: 'binary',
          description: 'Ảnh khuôn mặt để đăng ký',
        },
        requestId: {
          type: 'string',
          example: 'req-001',
          description: 'Mã định danh yêu cầu (Idempotency Key)',
        },
        reqId: {
          type: 'string',
          example: 'req-001',
          description: 'Alias cho requestId',
        },
      },
      required: ['image'],
    },
  })
  @ApiResponse({
    status: 201,
    type: RegisterFaceRes,
    description: 'RegistrationSuccess',
  })
  @ApiResponse({
    status: 400,
    description: 'Thiếu ảnh hoặc pose/liveness không hợp lệ',
  })
  @ApiResponse({ status: 403, description: 'Phát hiện spoof (giả mạo)' })
  @ApiResponse({ status: 404, description: 'Không tìm thấy khuôn mặt' })
  @UseInterceptors(FileInterceptor('image'))
  async registerFace(
    @UploadedFile() file: UploadedFile,
    @CurrentUser('userId') userId: string,
    @Body('requestId') requestId: string,
    @Body('facePose') facePose: FacePoseStatus,
  ): Promise<RegisterFaceRes> {
    if (!file?.buffer) {
      throw new BadRequestException('Vui lòng tải lên ảnh khuôn mặt.');
    }

    const reqDto = RegisterFaceReq.of(userId, requestId, facePose);

    return this.faceBiometricService.registerFace(file.buffer, reqDto);
  }
}
