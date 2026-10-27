import { CheckInOutDashboardReq } from '../../dto/req.dto';
import { CheckInOutDashboardRes } from '../../dto/res.dto';

export interface CheckInOutStatisticUsecase {
  getCheckInOutStatistic(
    req: CheckInOutDashboardReq,
  ): Promise<CheckInOutDashboardRes[]>;
}
