import { Body, Controller, Get, Post } from '@nestjs/common';
import { AuthService } from './auth.service';
import { DevLoginDto, ExchangeTokenDto, RegisterDto } from './dto/auth.dto';
import { Public } from '../common/decorators/public.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthUser } from '../common/interfaces/auth-user.interface';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Public()
  @Post('exchange')
  exchange(@Body() dto: ExchangeTokenDto) {
    return this.authService.exchange(dto);
  }

  @Public()
  @Post('dev-login')
  devLogin(@Body() dto: DevLoginDto) {
    return this.authService.devLogin(dto);
  }

  @Get('me')
  me(@CurrentUser() user: AuthUser) {
    return this.authService.me(user);
  }

  @Post('logout')
  logout(@CurrentUser() user: AuthUser) {
    return this.authService.logout(user);
  }
}
