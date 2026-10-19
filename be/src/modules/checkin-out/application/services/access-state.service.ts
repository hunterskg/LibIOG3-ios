import { Injectable } from '@nestjs/common';
import { EntityManager } from 'typeorm';
import { AccessLog } from '../../../access/domain/entities/access-log.entity';
import { AccessAction } from '../../../access/domain/enums/access-action.enum';
import { AccessResult } from '../../../access/domain/enums/access-result.enum';

export enum ReaderAccessState {
  IN = 'IN',
  OUT = 'OUT',
}

@Injectable()
export class AccessStateService {
  async getCurrentState(
    manager: EntityManager,
    readerId: string,
  ): Promise<ReaderAccessState> {
    const accessLogRepository = manager.getRepository(AccessLog);

    const latestLog = await accessLogRepository.findOne({
      where: {
        readerId,
        result: AccessResult.SUCCESS,
      },
      order: {
        occurredAt: 'DESC',
        createdAt: 'DESC',
        id: 'DESC',
      },
    });

    if (!latestLog) {
      return ReaderAccessState.OUT;
    }

    if (latestLog.action === AccessAction.CHECK_IN) {
      return ReaderAccessState.IN;
    }

    return ReaderAccessState.OUT;
  }
}
