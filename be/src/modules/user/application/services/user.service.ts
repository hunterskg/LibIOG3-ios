import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../domain/entities/user.entity';
import { UserRes } from '../../domain/dtos/res.dto';

@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  async getById(id: number): Promise<User | null> {
    return this.userRepo.findOne({
      where: { id },
      relations: { reader: true, staff: true },
    });
  }

  async isExist(id: number): Promise<boolean> {
    return this.userRepo.existsBy({ id });
  }

  async getUserById(id: number | string): Promise<UserRes> {
    const numericId = typeof id === 'string' ? Number(id) : id;
    const user = await this.getById(numericId);
    if (!user) {
      throw new NotFoundException(`User with id ${id} not found`);
    }
    return {
      userId: user.id.toString(),
      email: user.email,
      role: user.role,
    };
  }
}
