export const ROLES = {
  PASSENGER: 'PASSENGER',
  DRIVER: 'DRIVER',
  ADMIN: 'ADMIN',
  TRANSPORT_AUTHORITY: 'TRANSPORT_AUTHORITY',
} as const;

export type RoleCode = (typeof ROLES)[keyof typeof ROLES];

export const ADMIN_ROLES: RoleCode[] = [ROLES.ADMIN, ROLES.TRANSPORT_AUTHORITY];
