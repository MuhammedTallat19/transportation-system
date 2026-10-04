import { RoleCode } from '../constants/roles.constant';

export interface AuthUser {
  userId: string;
  firebaseUid: string;
  email?: string | null;
  roles: RoleCode[];
  governorateId?: string | null;
}
