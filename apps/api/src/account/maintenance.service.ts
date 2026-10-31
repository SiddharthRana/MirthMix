import {
  Inject,
  Injectable,
  Logger,
  type OnApplicationShutdown,
  type OnModuleInit,
} from '@nestjs/common';
import { and, isNotNull, lt } from 'drizzle-orm';
import { ENV, type Env } from '../config/env';
import { Database } from '../database/database.module';
import { profiles, webhookEvents } from '../database/schema';
import { AccountService } from './account.service';

export const WEBHOOK_PAYLOAD_RETENTION_DAYS = 30;
const DAY_MS = 86_400_000;

export interface MaintenanceResult {
  webhookPayloads: number;
  pendingDeletions: { completed: number; remaining: number };
}

/**
 * Privacy housekeeping, once an hour after startup: drops provider webhook payloads (which can
 * contain an email address) after 30 days and retries pending account deletions. A plain timer is
 * enough for one API instance; with several, each runs it and the work is idempotent.
 */
@Injectable()
export class MaintenanceService implements OnModuleInit, OnApplicationShutdown {
  private readonly logger = new Logger(MaintenanceService.name);
  private timer: NodeJS.Timeout | null = null;

  constructor(
    private readonly database: Database,
    private readonly accounts: AccountService,
    @Inject(ENV) private readonly env: Env,
  ) {}

  onModuleInit(): void {
    if (!this.env.MAINTENANCE_ENABLED) return;
    this.timer = setInterval(() => {
      this.run().then(
        (r) =>
          this.logger.log(
            `Maintenance: ${r.webhookPayloads} payloads removed; deletions completed ` +
              `${r.pendingDeletions.completed}, pending ${r.pendingDeletions.remaining}`,
          ),
        (err: unknown) =>
          this.logger.error(`Maintenance failed: ${err instanceof Error ? err.message : err}`),
      );
    }, 3_600_000);
    this.timer.unref();
  }

  onApplicationShutdown(): void {
    if (this.timer) clearInterval(this.timer);
  }

  async run(now = new Date()): Promise<MaintenanceResult> {
    const db = this.database.db;
    const payloadCutoff = new Date(now.getTime() - WEBHOOK_PAYLOAD_RETENTION_DAYS * DAY_MS);
    const payloads = await db
      .update(webhookEvents)
      .set({ payload: null })
      .where(and(lt(webhookEvents.receivedAt, payloadCutoff), isNotNull(webhookEvents.payload)))
      .returning({ id: webhookEvents.id });

    const pending = await db
      .select({ id: profiles.id })
      .from(profiles)
      .where(isNotNull(profiles.deletionRequestedAt));
    let completed = 0;
    for (const p of pending) if (await this.accounts.deleteAuthUser(p.id)) completed++;

    return {
      webhookPayloads: payloads.length,
      pendingDeletions: { completed, remaining: pending.length - completed },
    };
  }
}
