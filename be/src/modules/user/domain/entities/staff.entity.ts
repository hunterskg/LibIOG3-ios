import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';
import { UserAuth } from './user-auth.entity';

@Entity()
export class Staff extends UserAuth {
  @PrimaryGeneratedColumn('uuid')
  id!: number;

  @Column()
  name!: string;
}
