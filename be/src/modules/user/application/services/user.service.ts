import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../domain/entities/user.entity';
import { UserAuthRes, UserRes } from '../../domain/dtos/res.dto';
import { Role } from '../../domain/enums/role.enum';

@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  async getById(id: string): Promise<UserRes | null> {
    const user = await this.userRepo.findOne({
      where: { id },
      relations: { reader: true, staff: true },
    });

    return user ? UserRes.of(user) : null;
  }

  async getByIdForAuth(id: string): Promise<UserAuthRes | null> {
    const user = await this.userRepo.findOne({
      where: { id },
      relations: { reader: true, staff: true },
    });

    return user
      ? { ...UserRes.of(user), passwordHash: user.passwordHash }
      : null;
  }

  async isExist(id: string): Promise<boolean> {
    return this.userRepo.existsBy({ id });
  }

  /**
   * @throws {NotFoundException} Khi không tìm thấy user theo email
   */
  async getUserByEmailForAuth(email: string): Promise<UserAuthRes> {
    const user = await this.userRepo.findOne({ where: { email: email } });
    if (!user) {
      throw new NotFoundException(`User with email ${email} not found`);
    }
    return {
      userId: user.id.toString(),
      email: user.email,
      role: user.role,
      passwordHash: user.passwordHash,
      isActive: user.isActived(),
    };
  }

  async isEmailExist(email: string): Promise<boolean> {
    const user = await this.userRepo.findOne({ where: { email } });
    return !!user;
  }

  async createUser(
    email: string,
    passwordHash: string,
    role: Role,
  ): Promise<User> {
    const newUser = this.userRepo.create({
      email,
      passwordHash,
      role,
    });
    return this.userRepo.save(newUser);
  }

  /**
   * @throws {NotFoundException} Not found user with the given id
   */
  async updatePassword(userId: string, newPasswordHash: string): Promise<void> {
    const user = await this.userRepo.findOne({ where: { id: userId } });

    if (!user) {
      throw new NotFoundException(`User with id ${userId} not found`);
    }

    user.updatePassword(newPasswordHash);
    await this.userRepo.save(user);
  }
}
