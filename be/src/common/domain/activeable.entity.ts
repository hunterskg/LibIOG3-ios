import { Column } from 'typeorm';

export abstract class ActiveableEntity {
  @Column({ default: true })
  isActive: boolean;

  isActived(): boolean {
    return this.isActive;
  }

  activate(): void {
    this.isActive = true;
  }

  deactivate(): void {
    this.isActive = false;
  }
}
