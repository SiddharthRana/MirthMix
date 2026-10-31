import { Module } from '@nestjs/common';
import { ENV, type Env } from '../config/env';
import { AccountController } from './account.controller';
import { AccountService } from './account.service';
import { AUTH_ADMIN, SupabaseAuthAdmin, UnconfiguredAuthAdmin } from './auth-admin';
import { MaintenanceService } from './maintenance.service';

@Module({
  controllers: [AccountController],
  providers: [
    AccountService,
    MaintenanceService,
    {
      provide: AUTH_ADMIN,
      inject: [ENV],
      useFactory: (env: Env) =>
        env.SUPABASE_SECRET_KEY
          ? new SupabaseAuthAdmin(env.SUPABASE_URL, env.SUPABASE_SECRET_KEY)
          : new UnconfiguredAuthAdmin(),
    },
  ],
})
export class AccountModule {}
