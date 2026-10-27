import { OccupancyDashboardRes } from '../../dto/res.dto';

/**
 * Giá trị nghiệp vụ: Cung cấp thông tin trực quan về số người đang có mặt thực tế và năng lực đáp ứng của thư viện.
 */
export interface OccupancyStatisticUsecase {
  /**
   * Lấy số người hiện tại đang có mặt trong thư viện cùng tỷ lệ sức chứa và trạng thái cảnh báo.
   * @returns Thông tin số người, sức chứa tối đa, tỷ lệ lấp đầy và trạng thái
   */
  getCurrentOccupancy(): Promise<OccupancyDashboardRes>;
}
