import { expect, test } from '@playwright/test';

const API = 'http://localhost:4000';

const config = (available: boolean) => ({
  enabled: available,
  web: { provider: 'paddle', available, intervals: available ? ['monthly', 'annual'] : [] },
  googlePlay: { available, packageName: 'com.mirthmix.app', subscriptionId: 'mirthmix_premium' },
});

test('the Premium page shows plans, indicative prices and what premium adds', async ({ page }) => {
  await page.goto('/');
  await page
    .getByRole('navigation', { name: 'Main' })
    .getByRole('link', { name: 'Premium' })
    .click();
  await expect(page.getByRole('heading', { level: 1, name: 'Premium' })).toBeVisible();
  const premium = page.getByRole('region', { name: 'MirthMix Premium' });
  await expect(premium).toContainText('₹99 a month or ₹699 a year');
  await expect(premium).toContainText('$2.99 a month or $19.99 a year');
  const included = page.getByRole('region', { name: 'Premium categories' });
  await expect(included.getByRole('listitem').first()).toContainText(/\d+ questions?/);
});

test('without a reachable API, checkout is honestly unavailable', async ({ page }) => {
  await page.route(`${API}/**`, (route) => route.abort());
  await page.goto('/pricing');
  await expect(page.getByText('Premium isn’t on sale on the website yet.')).toBeVisible();
  await expect(page.getByRole('button', { name: /Subscribe/ })).toHaveCount(0);
});

test('with billing on, a signed-out visitor is asked to sign in first', async ({ page }) => {
  await page.route(`${API}/v1/billing/config`, (route) => route.fulfill({ json: config(true) }));
  await page.goto('/pricing');
  // This build has no Supabase configuration, so nobody can be signed in.
  await page.getByRole('link', { name: 'Sign in to subscribe' }).click();
  await expect(page).toHaveURL(/\/account\?next=pricing/);
  await expect(page.getByText('Accounts aren’t available on this website yet.')).toBeVisible();
});

test('the checkout page explains when Paddle can’t be opened', async ({ page }) => {
  await page.goto('/checkout/paddle?_ptxn=txn_1');
  await expect(page.getByRole('heading', { level: 1 })).toHaveText('Checkout couldn’t be opened');
  await page.getByRole('link', { name: 'Back to Premium' }).click();
  await expect(page.getByRole('heading', { level: 1, name: 'Premium' })).toBeVisible();
});

test('the web player stays on free categories', async ({ page }) => {
  await page.goto('/play');
  await expect(page.getByText('Time Travel')).toHaveCount(0);
});
