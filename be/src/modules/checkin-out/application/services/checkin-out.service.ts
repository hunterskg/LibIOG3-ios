import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { DataSource, EntityManager } from 'typeorm';
import { createHash } from 'crypto';
import { QrTokenStatus } from '../../../qr/domain/enums/qr-token-status.enum';

export type CheckInOutAction = 'CHECK_IN' | 'CHECK_OUT';

interface CheckInOutInput {
  token: string;
  action: CheckInOutAction;
}

@Injectable()
export class CheckInOutService {
  constructor(private readonly dataSource: DataSource) {}

  async checkInOut(staffId: string, input: CheckInOutInput) {
    const { token, action } = input;

    if (!staffId) {
      throw new UnauthorizedException('Không xác định được tài khoản Staff.');
    }

    if (!token || !/^[a-f0-9]{64}$/i.test(token)) {
      throw new BadRequestException('QR token không hợp lệ.');
    }

    if (action !== 'CHECK_IN' && action !== 'CHECK_OUT') {
      throw new BadRequestException('Action phải là CHECK_IN hoặc CHECK_OUT.');
    }

    const tokenHash = createHash('sha256').update(token).digest('hex');

    return this.dataSource.transaction(async (manager: EntityManager) => {
      const qrRows = await manager.query(
        `
          SELECT
            qt.id AS qr_id,
            qt.reader_id,
            qt.status AS qr_status,
            qt.expires_at,
            qt.used_at,
            qt.revoked_at
          FROM qr_tokens qt
          WHERE qt.token_hash = $1
          FOR UPDATE
          `,
        [tokenHash],
      );

      if (qrRows.length === 0) {
        throw new UnauthorizedException('QR không tồn tại hoặc không hợp lệ.');
      }

      const qr = qrRows[0];

      if (
        qr.qr_status !== QrTokenStatus.ACTIVE ||
        qr.used_at !== null ||
        qr.revoked_at !== null ||
        new Date(qr.expires_at).getTime() <= Date.now()
      ) {
        throw new UnauthorizedException(
          'QR đã hết hạn, đã sử dụng hoặc bị vô hiệu hóa.',
        );
      }

      const readerId: string = qr.reader_id;

      await manager.query(
        `
          SELECT pg_advisory_xact_lock(
            hashtextextended($1::text, 0)
          )
          `,
        [readerId],
      );

      const staffRows = await manager.query(
        `
          SELECT u.id
          FROM users u
          WHERE u.id = $1
            AND u.role IN ('staff', 'admin')
            AND u.status = 'active'
          `,
        [staffId],
      );

      if (staffRows.length === 0) {
        throw new ForbiddenException(
          'Tài khoản không phải Staff đang hoạt động.',
        );
      }

      const deviceRows = await manager.query(
        `
          SELECT
            d.id AS device_id,
            d.gate_id
          FROM devices d
          WHERE d.staff_id = $1
            AND d.status = 'ACTIVE'
            AND d.revoked_at IS NULL
            AND (
              d.expired_at IS NULL
              OR d.expired_at > NOW()
            )
            AND d.gate_id IS NOT NULL
          ORDER BY d.created_at DESC
          LIMIT 1
          `,
        [staffId],
      );

      if (deviceRows.length === 0) {
        throw new ForbiddenException(
          'Staff chưa có thiết bị hợp lệ được gắn với cổng.',
        );
      }

      const deviceId: string = deviceRows[0].device_id;
      const gateId: string = deviceRows[0].gate_id;

      const latestLogs = await manager.query(
        `
          SELECT action, result
          FROM access_logs
          WHERE reader_id = $1
            AND result = 'SUCCESS'
          ORDER BY occurred_at DESC, created_at DESC, id DESC
          LIMIT 1
          `,
        [readerId],
      );

      let currentState: 'IN' | 'OUT' = 'OUT';

      if (latestLogs.length > 0) {
        const latestAction = latestLogs[0].action;

        if (latestAction === 'CHECK_IN') {
          currentState = 'IN';
        } else if (
          latestAction === 'CHECK_OUT' ||
          latestAction === 'AUTO_CHECK_OUT'
        ) {
          currentState = 'OUT';
        }
      }

      let reason: string | null = null;

      if (action === 'CHECK_IN' && currentState === 'IN') {
        reason = 'Reader đã check-in, không thể check-in lần nữa.';
      } else if (action === 'CHECK_OUT' && currentState === 'OUT') {
        reason = 'Reader chưa check-in hoặc đã check-out.';
      }

      const result = reason ? 'DENIED' : 'SUCCESS';

      const logRows = await manager.query(
        `
          INSERT INTO access_logs (
            reader_id,
            gate_id,
            device_id,
            staff_id,
            action,
            method,
            result,
            reason,
            occurred_at
          )
          VALUES (
            $1, $2, $3, $4, $5, 'QR', $6, $7, NOW()
          )
          RETURNING
            id,
            reader_id,
            gate_id,
            device_id,
            staff_id,
            action,
            method,
            result,
            reason,
            occurred_at
          `,
        [readerId, gateId, deviceId, staffId, action, result, reason],
      );

      const consumedRows = await manager.query(
        `
          UPDATE qr_tokens
          SET used_at = NOW(),
              status = $2
          WHERE id = $1
            AND status = $3
            AND used_at IS NULL
            AND revoked_at IS NULL
            AND expires_at > NOW()
          RETURNING id
          `,
        [qr.qr_id, QrTokenStatus.USED, QrTokenStatus.ACTIVE],
      );

      if (consumedRows.length === 0) {
        throw new UnauthorizedException('QR đã hết hạn hoặc đã được sử dụng.');
      }

      const accessLog = logRows[0];

      return {
        success: result === 'SUCCESS',
        message:
          reason ??
          (action === 'CHECK_IN'
            ? 'Check-in thành công.'
            : 'Check-out thành công.'),
        data: {
          accessLogId: accessLog.id,
          readerId,
          staffId,
          gateId,
          deviceId,
          action: accessLog.action,
          method: accessLog.method,
          result: accessLog.result,
          reason: accessLog.reason,
          occurredAt: accessLog.occurred_at,
          currentState:
            result === 'DENIED'
              ? currentState
              : action === 'CHECK_IN'
                ? 'IN'
                : 'OUT',
        },
      };
    });
  }
}
