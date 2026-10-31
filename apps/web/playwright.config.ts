import { defineConfig, devices } from '@playwright/test';

const PORT = 3100;

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? 'github' : 'list',
  use: { baseURL: `http://localhost:${PORT}`, trace: 'retain-on-failure' },
  projects: [
    { name: 'desktop', use: { ...devices['Desktop Chrome'] } },
    { name: 'mobile', use: { ...devices['Pixel 7'] } },
    // Accessibility checks again in dark mode (colour contrast differs).
    {
      name: 'desktop-dark',
      use: { ...devices['Desktop Chrome'], colorScheme: 'dark' },
      grep: /WCAG/,
    },
  ],
  // Tests run against the static export (`pnpm build` → out/) served by Cloudflare's local Pages
  // server, so clean URLs, 404s and public/_headers behave as in production.
  webServer: {
    command: `pnpm exec wrangler pages dev out --port ${PORT} --compatibility-date 2026-10-01`,
    url: `http://localhost:${PORT}`,
    env: { WRANGLER_SEND_METRICS: 'false' },
    reuseExistingServer: !process.env.CI,
    timeout: 60_000,
  },
});
