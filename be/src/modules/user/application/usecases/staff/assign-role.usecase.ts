import { Role } from '../../../domain/enums/role.enum';

/* 
    rules: only admin can assign role to staff
    - check if the staff exists
    - check if the staff is a staff
    - check if the role is valid
    system must have at least one active admin
    admin cannot assign role to himself
*/
export interface AssignRoleUsecase {
  assignRole(staffId: string, role: Role): Promise<void>;
}
