import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import { FirebaseService } from './firebase.service';
import { DevLoginDto, ExchangeTokenDto, RegisterDto } from './dto/auth.dto';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { RoleCode } from '../common/constants/roles.constant';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly firebase: FirebaseService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async register(dto: RegisterDto) {
    const decoded = await this.firebase.verifyIdToken(dto.firebaseIdToken);
    const existing = await this.prisma.user.findUnique({ where: { firebase_uid: decoded.uid } });
    if (existing) {
      throw new ConflictException({ code: 'USER_EXISTS', message: 'User already registered' });
    }

    const role = await this.prisma.role.findUnique({ where: { code: dto.role } });
    if (!role) {
      throw new BadRequestException({ code: 'INVALID_ROLE', message: 'Invalid role' });
    }

    const user = await this.prisma.user.create({
      data: {
        firebase_uid: decoded.uid,
        full_name: dto.fullName,
        phone_number: dto.phoneNumber,
        email: decoded.email ?? undefined,
        governorate_id: dto.governorateId,
        status: 'PENDING_VERIFICATION',
        preferred_language: 'ar',
        roles: { create: { role_id: role.id } },
        ...(dto.role === 'PASSENGER' ? { passenger: { create: {} } } : {}),
        ...(dto.role === 'DRIVER'
          ? {
              driver: {
                create: {
                  license_number: `LIC-${Date.now()}`,
                  license_expiry: new Date('2030-01-01'),
                  national_id: `NID-${Date.now()}`,
                  status: 'OFF_DUTY',
                },
              },
            }
          : {}),
      },
      include: { roles: { include: { role: true } } },
    });

    return {
      id: user.id,
      fullName: user.full_name,
      status: user.status,
      roles: user.roles.map((r) => r.role.code),
    };
  }

  async exchange(dto: ExchangeTokenDto) {
    const decoded = await this.firebase.verifyIdToken(dto.idToken);
    const user = await this.prisma.user.findUnique({
      where: { firebase_uid: decoded.uid },
      include: { roles: { include: { role: true } } },
    });
    if (!user) {
      throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'User not registered' });
    }
    return this.issueToken(user.id, user.firebase_uid, user.email, user.governorate_id, user.roles.map((r) => r.role.code as RoleCode));
  }

  async devLogin(dto: DevLoginDto) {
    if (this.configService.get<string>('DEV_AUTH') !== 'true') {
      throw new UnauthorizedException({ code: 'DEV_AUTH_DISABLED', message: 'Dev login is disabled' });
    }

    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
      include: { roles: { include: { role: true } } },
    });
    if (!user) {
      throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'No seeded user with this email' });
    }

    return this.issueToken(user.id, user.firebase_uid, user.email, user.governorate_id, user.roles.map((r) => r.role.code as RoleCode));
  }

  async me(user: AuthUser) {
    const dbUser = await this.prisma.user.findUnique({
      where: { id: user.userId },
      include: { roles: { include: { role: true } }, governorate: true, passenger: true, driver: true },
    });
    if (!dbUser) {
      throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'User not found' });
    }
    return {
      id: dbUser.id,
      fullName: dbUser.full_name,
      email: dbUser.email,
      phoneNumber: dbUser.phone_number,
      status: dbUser.status,
      governorateId: dbUser.governorate_id,
      governorateName: dbUser.governorate?.name,
      roles: dbUser.roles.map((r) => r.role.code),
      passenger: dbUser.passenger,
      driver: dbUser.driver,
    };
  }

  async logout(_user: AuthUser) {
    return { success: true };
  }

  private issueToken(
    userId: string,
    firebaseUid: string,
    email: string | null | undefined,
    governorateId: string | null | undefined,
    roles: RoleCode[],
  ) {
    const payload = {
      sub: userId,
      firebaseUid,
      email: email ?? undefined,
      roles,
      governorateId: governorateId ?? undefined,
    };
    const accessToken = this.jwtService.sign(payload);
    return { accessToken, tokenType: 'Bearer', expiresIn: 3600, userId, roles, governorateId };
  }
}
