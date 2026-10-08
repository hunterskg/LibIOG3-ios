import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { AuthService } from '../../application/services/auth.service';
import {
  ForgotPasswordReq,
  LoginReq,
  RefreshTokenReq,
  RegisterReq,
  ResendCodeReq,
  UpdatePasswordReq,
  VerifyEmailReq,
} from '../../dtos/req.dto';
import { AuthRes, RegisterPendingRes } from '../../dtos/response.dto';
import { ReaderRes } from '../../../user/domain/dtos/res.dto';
import { JwtGuard } from '../guard/jwt.guard';
import { CurrentUser } from '../decorators/current-user.decorator';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Login with email and password' })
  @ApiResponse({ status: 200, type: AuthRes, description: 'Login successful' })
  @ApiResponse({ status: 401, description: 'Invalid credentials' })
  async login(@Body() req: LoginReq): Promise<AuthRes> {
    return this.authService.login(req);
  }

  @Post('register')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Register a new user' })
  @ApiResponse({
    status: 200,
    type: RegisterPendingRes,
    description: 'Registration pending email verification',
  })
  @ApiResponse({ status: 409, description: 'Email already exists' })
  async register(@Body() req: RegisterReq): Promise<RegisterPendingRes> {
    return this.authService.register(req);
  }

  @Post('verify-email')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Verify email with OTP code' })
  @ApiResponse({
    status: 200,
    type: ReaderRes,
    description: 'Email verified and reader created successfully',
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid or expired verification code',
  })
  @ApiResponse({ status: 409, description: 'Email already exists' })
  async verifyEmail(@Body() req: VerifyEmailReq): Promise<ReaderRes> {
    return this.authService.verifyEmail(req);
  }

  @Post('resend-code')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Resend verification OTP code' })
  @ApiResponse({
    status: 200,
    description: 'Verification code resent successfully',
  })
  @ApiResponse({
    status: 404,
    description: 'Verification request not found or expired',
  })
  async resendCode(@Body() req: ResendCodeReq): Promise<{ message: string }> {
    await this.authService.resendCode(req.email);
    return { message: 'Verification code resent successfully' };
  }

  @Post('refresh-token')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Refresh access token using refresh token' })
  @ApiResponse({
    status: 200,
    type: AuthRes,
    description: 'Token refreshed successfully',
  })
  @ApiResponse({ status: 401, description: 'Invalid or expired refresh token' })
  async refreshToken(@Body() req: RefreshTokenReq): Promise<AuthRes> {
    return this.authService.refreshToken(req.refreshToken);
  }

  @Post('update-password')
  @UseGuards(JwtGuard)
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth('access-token')
  @ApiOperation({ summary: 'Update password for authenticated user' })
  @ApiResponse({ status: 200, description: 'Password updated successfully' })
  @ApiResponse({ status: 400, description: 'Old password is incorrect' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async updatePassword(
    @CurrentUser('userId') userId: string,
    @Body() req: UpdatePasswordReq,
  ): Promise<{ message: string }> {
    await this.authService.updatePassword(userId, req);
    return { message: 'Password updated successfully' };
  }

  @Post('forgot-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Request password reset via email' })
  @ApiResponse({ status: 200, description: 'Password reset request processed' })
  async forgotPassword(
    @Body() req: ForgotPasswordReq,
  ): Promise<{ message: string }> {
    await this.authService.forgotPassword(req);
    return { message: 'If the email exists, a reset instruction was sent' };
  }
}
