import AxeBuilder from '@axe-core/playwright';
import { expect, test } from '@playwright/test';

const pages = ['/', '/play', '/games', '/games/would-you-rather', '/privacy', '/terms'];

for (const path of pages) {
  test(`${path} has no WCAG A/AA violations`, async ({ page }) => {
    await page.goto(path);
    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'])
      .analyze();
    expect(results.violations).toEqual([]);
  });

  test(`${path} has one h1, a title and no horizontal scroll`, async ({ page }) => {
    await page.goto(path);
    await expect(page.locator('h1')).toHaveCount(1);
    await expect(page).toHaveTitle(/MirthMix/);
    const overflow = await page.evaluate(
      () => document.documentElement.scrollWidth > document.documentElement.clientWidth,
    );
    expect(overflow).toBe(false);
  });
}

test('navigation reaches every page', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('navigation', { name: 'Main' }).getByRole('link', { name: 'Games' }).click();
  await expect(page.getByRole('heading', { level: 1, name: 'Games' })).toBeVisible();
  await page.getByRole('link', { name: /Would You Rather/ }).click();
  await expect(page.getByRole('heading', { level: 1, name: 'Would You Rather' })).toBeVisible();
  await page
    .getByRole('navigation', { name: 'Footer' })
    .getByRole('link', { name: 'Privacy' })
    .click();
  await expect(page.getByRole('heading', { level: 1, name: 'Privacy' })).toBeVisible();
  await expect(page.getByRole('note')).toContainText('Draft placeholder');
  await page
    .getByRole('navigation', { name: 'Footer' })
    .getByRole('link', { name: 'Terms' })
    .click();
  await expect(page.getByRole('heading', { level: 1, name: 'Terms' })).toBeVisible();
});

test('the landing page demo plays real questions', async ({ page }) => {
  await page.goto('/');
  const demo = page.getByRole('region', { name: 'Try one: Would you rather…' });
  const options = demo.getByRole('button', { pressed: false });
  const first = (await options.first().textContent())!;
  await options.first().click();
  await expect(demo.getByRole('button', { pressed: true })).toHaveText(new RegExp(first));
  await expect(demo).toContainText('Now ask the room');
  await demo.getByRole('button', { name: 'Another one' }).click();
  await expect(demo.getByRole('button', { pressed: true })).toHaveCount(0);
  await expect(demo.getByRole('button', { pressed: false }).first()).not.toHaveText(first);
});

test('every mode is listed as available in the app', async ({ page }) => {
  await page.goto('/games');
  await expect(page.getByText('In the Android app')).toHaveCount(5);
  await expect(page.getByText('In development')).toHaveCount(0);
});

test('category counts come from the real content pack', async ({ page }) => {
  await page.goto('/games/would-you-rather');
  await expect(page.getByText('140 original questions in the starter pack.')).toBeVisible();
  await expect(page.getByText('Premium', { exact: true })).toBeVisible();
});

test('unknown pages return 404 with a way home', async ({ page }) => {
  const res = await page.goto('/does-not-exist');
  expect(res?.status()).toBe(404);
  await expect(page.getByRole('link', { name: 'Go home' })).toBeVisible();
});

test('sitemap and robots are served', async ({ request }) => {
  const sitemap = await (await request.get('/sitemap.xml')).text();
  expect(sitemap).toContain('/games/would-you-rather');
  expect(await (await request.get('/robots.txt')).text()).toContain('Sitemap:');
});

test('security headers are set', async ({ request }) => {
  const res = await request.get('/');
  expect(res.headers()['x-content-type-options']).toBe('nosniff');
  expect(res.headers()['x-powered-by']).toBeUndefined();
});
