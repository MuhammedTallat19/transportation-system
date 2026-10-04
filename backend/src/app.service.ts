import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getRoot() {
    return { status: 'Transportation App backend is running' };
  }
}
