import { test, expect } from '@playwright/test';

// Smoke tests for critical user flows on GrenadianBuzz web
// Notes:
// - Prefer configuring baseURL in playwright.config.ts for CI (recommended).
// - CI can set PLAYWRIGHT_BASE_URL or BASE_URL environment variable. Tests fall back to localhost:3000 for local dev.
const BASE = process.env.PLAYWRIGHT_BASE_URL || process.env.BASE_URL || 'http://localhost:3000';

test('landing page loads', async ({ page }) => {
  await page.goto(`${BASE}/`);
  await expect(page).toHaveTitle(/GrenadianBuzz/);
  await expect(page.locator('header')).toBeVisible();
});

test('signup flow smoke', async ({ page }) => {
  await page.goto(`${BASE}/signup`);
  await page.fill('input[name="email"]', 'test+smoke@example.com');
  await page.fill('input[name="password"]', 'Password123!');
  await page.click('button[type="submit"]');
  await expect(page).toHaveURL(/\/welcome/);
});
