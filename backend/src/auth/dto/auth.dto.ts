import { IsEmail, IsEnum, IsNotEmpty, IsOptional, IsString, IsUUID } from 'class-validator';
import { ROLES, RoleCode } from '../../common/constants/roles.constant';

export class RegisterDto {
  @IsString()
  @IsNotEmpty()
  firebaseIdToken!: string;

  @IsString()
  @IsNotEmpty()
  fullName!: string;

  @IsOptional()
  @IsString()
  phoneNumber?: string;

  @IsUUID()
  governorateId!: string;

  @IsEnum(ROLES)
  role!: RoleCode;
}

export class ExchangeTokenDto {
  @IsString()
  @IsNotEmpty()
  idToken!: string;
}

export class DevLoginDto {
  @IsEmail()
  email!: string;
}
