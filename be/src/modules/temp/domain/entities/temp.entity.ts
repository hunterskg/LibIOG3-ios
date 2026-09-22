import { TempStatus } from '../enums/temp-status.enum';

export class Temp {
  id!: string;
  name!: string;
  status!: TempStatus;
  createdAt!: Date;
}
