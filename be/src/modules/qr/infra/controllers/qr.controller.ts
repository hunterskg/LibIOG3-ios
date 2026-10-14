import { Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UseGuards, Body } from '@nestjs/common';
import { RoleGuard } from '../../../auth/infra/guard/role.guard';
import { JwtGuard } from '../../../auth/infra/guard/jwt.guard';
import { QrService } from '../../application/services/qr.service';
import { Roles } from '../../../auth/infra/decorators/role.decorator';
import { CurrentUser } from '../../../auth/infra/decorators/current-user.decorator';
import { Role } from '../../../user/domain/enums/role.enum';
import { VerifyQrTokenDto } from '../dto/verify-qr-token.dto';
@ApiTags('QR Tokens')
@ApiBearerAuth('access-token')
@UseGuards(JwtGuard, RoleGuard)
@Controller('qr-tokens')
export class QrController {
    constructor(private readonly qrService: QrService) { }

    @Post()
    @Roles(Role.READER)
    @HttpCode(HttpStatus.CREATED)
    createQrToken(@CurrentUser('userId') userId: string) {
        return this.qrService.createQrToken(userId);
    }

    @Post('verify')
    @Roles(Role.DEVICE)
    @HttpCode(HttpStatus.OK)
    verifyQrToken(@Body() dto: VerifyQrTokenDto) {
        return this.qrService.verifyAndConsumeQrToken(dto.token);
    }

}




