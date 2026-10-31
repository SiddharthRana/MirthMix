import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Equals, IsString } from 'class-validator';
import { PLAN_IDS, SUBSCRIPTION_STATUSES } from '@mirthmix/plans';

export class DeleteAccountBody {
  @ApiProperty({ example: 'DELETE', description: 'Must be exactly "DELETE"' })
  @IsString()
  @Equals('DELETE', { message: 'Type DELETE to confirm account deletion.' })
  confirm: string;
}

class AccountPlanDto {
  @ApiProperty({ enum: PLAN_IDS }) id: string;
  @ApiProperty() name: string;
  @ApiProperty() paid: boolean;
  @ApiProperty({ enum: ['default', 'subscription'] }) source: 'default' | 'subscription';
}

class EntitlementsDto {
  @ApiProperty() premiumContent: boolean;
}

class AccountSubscriptionDto {
  @ApiProperty() provider: string;
  @ApiProperty({ enum: PLAN_IDS }) planId: string;
  @ApiProperty({ enum: SUBSCRIPTION_STATUSES }) status: string;
  @ApiProperty({ type: String, nullable: true, enum: ['monthly', 'annual'] }) interval:
    'monthly' | 'annual' | null;
  @ApiProperty({ type: String, nullable: true, format: 'date-time' }) currentPeriodEnd:
    string | null;
  @ApiProperty() cancelAtPeriodEnd: boolean;
}

export class AccountDtoClass {
  @ApiProperty({ format: 'uuid' }) id: string;
  @ApiPropertyOptional() email?: string;
  @ApiProperty({ format: 'date-time' }) createdAt: string;
  @ApiProperty({ type: AccountPlanDto }) plan: AccountPlanDto;
  @ApiProperty({ type: EntitlementsDto }) entitlements: EntitlementsDto;
  @ApiProperty({
    type: String,
    nullable: true,
    format: 'date-time',
    description: 'Re-check the entitlement after this moment (end of the paid period)',
  })
  validUntil: string | null;
  @ApiProperty({ type: [AccountSubscriptionDto] }) subscriptions: AccountSubscriptionDto[];
}

export class DeleteAccountResponse {
  @ApiProperty({
    enum: ['deleted', 'pending'],
    description: 'pending: the account is disabled; the sign-in record will be removed shortly',
  })
  status: 'deleted' | 'pending';
}
