import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

@Injectable()
export class FirebaseService {
  private initialized = false;

  constructor(private readonly configService: ConfigService) {
    this.ensureInit();
  }

  private ensureInit() {
    if (this.initialized || admin.apps.length) {
      this.initialized = true;
      return;
    }

    const projectId = this.configService.get<string>('FIREBASE_PROJECT_ID');
    if (!projectId) {
      return;
    }

    try {
      admin.initializeApp({ projectId });
      this.initialized = true;
    } catch {
      // Dev mode may run without Firebase credentials
    }
  }

  async verifyIdToken(idToken: string): Promise<admin.auth.DecodedIdToken> {
    this.ensureInit();
    if (!admin.apps.length) {
      if (this.configService.get<string>('DEV_AUTH') === 'true') {
        return {
          uid: `dev-${idToken.slice(0, 20)}`,
          email: idToken.includes('@') ? idToken : undefined,
        } as admin.auth.DecodedIdToken;
      }
      throw new UnauthorizedException({
        code: 'FIREBASE_NOT_CONFIGURED',
        message: 'Firebase Admin SDK is not configured',
      });
    }
    return admin.auth().verifyIdToken(idToken);
  }
}
