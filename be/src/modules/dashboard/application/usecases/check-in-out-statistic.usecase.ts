import { CheckInOutDashboardReq } from '../../dto/req.dto';
import { CheckInOutDashboardRes } from '../../dto/res.dto';

export interface CheckInOutStatisticUsecase {
  /**
   * Thống kê biến động số lượng Check-in/Check-out theo từng mốc thời gian.
   * @param req Khoảng thời gian và bước nhảy intervalMin
   * @returns Danh sách các bucket thống kê lượt ra/vào và lượng người trong viện
   */
  getCheckInOutStatistic(
    req: CheckInOutDashboardReq,
  ): Promise<CheckInOutDashboardRes[]>;
}
