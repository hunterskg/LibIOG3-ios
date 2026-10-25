export enum CapacityStatus {
  NORMAL = 'NORMAL',
  WARNING = 'WARNING',
  FULL = 'FULL',
}

export const NORMAL_CAPACITY_THRESHOLD = 70;
export const WARNING_CAPACITY_THRESHOLD = 90;

export function getCapacityStatus(capacity: number): CapacityStatus {
  if (capacity < 70) {
    return CapacityStatus.NORMAL;
  } else if (capacity < 90) {
    return CapacityStatus.WARNING;
  } else {
    return CapacityStatus.FULL;
  }
}
