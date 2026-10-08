import { Injectable, Logger } from '@nestjs/common';
import { MailerService as NestMailer } from '@nestjs-modules/mailer';
import {
  MailService,
  SendMailOptions,
} from '../../application/interface/mail-service.interface';

@Injectable()
export class NestMailerService implements MailService {
  private readonly logger = new Logger(NestMailerService.name);

  constructor(private readonly mailerService: NestMailer) {}

  async sendMail(options: SendMailOptions): Promise<void> {
    const recipient = Array.isArray(options.to)
      ? options.to
          .map((r) => (typeof r === 'string' ? r : r.address))
          .join(', ')
      : typeof options.to === 'string'
        ? options.to
        : (options.to?.address ?? 'unknown');

    try {
      await this.mailerService.sendMail(options);
      this.logger.log(`Mail sent successfully to: ${recipient}`);
    } catch (error) {
      this.logger.error(
        `Failed to send email to ${recipient}: ${error instanceof Error ? error.message : String(error)}`,
        error instanceof Error ? error.stack : undefined,
      );
      throw error;
    }
  }
}
