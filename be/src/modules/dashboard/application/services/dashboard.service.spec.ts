import { describe, it, expect, beforeEach, jest } from '@jest/globals';

jest.mock('@nestjs/typeorm', () => ({
  InjectRepository: () => () => {},
  getRepositoryToken: (entity: any) => entity,
}));

import { DashboardService } from './dashboard.service';
import { AccessLog } from '../../../access/domain/entities/access-log.entity';
import { Repository } from 'typeorm';

describe('DashboardService', () => {
  let service: DashboardService;
  let accessLogRepo: jest.Mocked<Repository<AccessLog>>;

  beforeEach(() => {
    accessLogRepo = {
      query: jest.fn(),
    } as unknown as jest.Mocked<Repository<AccessLog>>;

    service = new DashboardService(accessLogRepo);
  });

  it('tính đúng check-in, check-out, peak và lowest theo từng interval', async () => {
    const startDate = new Date('2026-10-26T08:00:00.000Z');
    const endDate = new Date('2026-10-26T10:00:00.000Z');
    const intervalMin = 60;

    accessLogRepo.query
      .mockResolvedValueOnce([{ count: 2 }])
      .mockResolvedValueOnce([
        {
          startDate: '2026-10-26T08:00:00.000Z',
          checkInCount: 1,
          checkOutCount: 1,
        },
        {
          startDate: '2026-10-26T09:00:00.000Z',
          checkInCount: 2,
          checkOutCount: 0,
        },
      ]);

    const result = await service.getCheckInOutStatistic({
      startDate,
      endDate,
      intervalMin,
    });

    expect(result).toHaveLength(2);

    expect(result[0]).toEqual({
      startDate: new Date('2026-10-26T08:00:00.000Z'),
      intervalMin: 60,
      checkInCount: 1,
      checkOutCount: 1,
      peakPeopleCount: 3,
      lowestPeopleCount: 2,
    });

    expect(result[1]).toEqual({
      startDate: new Date('2026-10-26T09:00:00.000Z'),
      intervalMin: 60,
      checkInCount: 2,
      checkOutCount: 0,
      peakPeopleCount: 4,
      lowestPeopleCount: 2,
    });
  });

  it('trả về mảng rỗng khi khoảng thời gian không hợp lệ', async () => {
    const result = await service.getCheckInOutStatistic({
      startDate: new Date('2026-10-26T10:00:00.000Z'),
      endDate: new Date('2026-10-26T08:00:00.000Z'),
      intervalMin: 60,
    });

    expect(result).toEqual([]);
  });
});
