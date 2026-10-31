import { Body, Controller, Delete, Get, HttpCode } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiForbiddenResponse,
  ApiOkResponse,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import type { AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/decorators';
import { ApiErrorDto } from '../common/api-error';
import { AccountDtoClass, DeleteAccountBody, DeleteAccountResponse } from './account.dto';
import { AccountService } from './account.service';

@ApiTags('account')
@ApiBearerAuth()
@ApiUnauthorizedResponse({ type: ApiErrorDto })
@ApiForbiddenResponse({ type: ApiErrorDto, description: 'account_deleted' })
@Controller('me')
export class AccountController {
  constructor(private readonly accounts: AccountService) {}

  /** The signed-in purchaser: current plan (server-side entitlements) and subscriptions. */
  @Get()
  @ApiOkResponse({ type: AccountDtoClass })
  me(@CurrentUser() user: AuthUser): Promise<AccountDtoClass> {
    return this.accounts.get(user);
  }

  /** Permanently delete the account. Body must be {"confirm":"DELETE"}. */
  @Delete()
  @HttpCode(200)
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @ApiOkResponse({ type: DeleteAccountResponse })
  @ApiBadRequestResponse({ type: ApiErrorDto })
  delete(
    @CurrentUser() user: AuthUser,
    @Body() _body: DeleteAccountBody,
  ): Promise<DeleteAccountResponse> {
    return this.accounts.delete(user);
  }
}
