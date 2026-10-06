import { Column } from 'typeorm';

export abstract class UserAuth {
  @Column({ unique: true })
  email!: string;

  @Column({ name: 'password_hash' })
  passwordHash!: string;
}
