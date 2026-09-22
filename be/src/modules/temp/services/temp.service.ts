import { Injectable } from '@nestjs/common';
import { Temp } from '../domain/entities/temp.entity';
import { TempStatus } from '../domain/enums/temp-status.enum';

@Injectable()
export class TempService {
  // ponytail: In-memory store; upgrade path: inject DB repository when ORM added.
  private readonly items: Temp[] = [];

  findAll(): Temp[] {
    return this.items;
  }

  findOne(id: string): Temp | undefined {
    return this.items.find((item) => item.id === id);
  }

  create(name: string): Temp {
    const item: Temp = {
      id: Date.now().toString(),
      name,
      status: TempStatus.ACTIVE,
      createdAt: new Date(),
    };
    this.items.push(item);
    return item;
  }
}
