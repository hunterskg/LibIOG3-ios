import { Role } from '../enums/role.enum';

export class UserRes {
  userId!: string;
  email!: string;
  role!: Role;

  static of(user: { id: number; email: string; role: Role }): UserRes {
    const res = new UserRes();
    res.userId = user.id.toString();
    res.email = user.email;
    res.role = user.role;
    return res;
  }
}
