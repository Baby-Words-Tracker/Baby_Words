import { test, expect } from '@playwright/test';

const APP_URL = 'http://localhost:4200';

test('loads Wordbuds home page', async ({ page }) => {
  await page.goto(APP_URL);

  await expect(page).toHaveTitle(/Wordbuds/i);
  await expect(page.locator('app-root')).toBeVisible();
  await expect(page.getByRole('heading', { name: 'Sign in' })).toBeVisible();
});

test('shows basic login form controls', async ({ page }) => {
  await page.goto(APP_URL);

  await expect(page.getByLabel('Email')).toBeVisible();
  await expect(page.getByLabel('Password')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Log in' })).toBeVisible();
});

test('keeps login button disabled when form is empty', async ({ page }) => {
  await page.goto(APP_URL);

  const loginButton = page.getByRole('button', { name: 'Log in' });
  await expect(loginButton).toBeDisabled();
});

test('enables login button when email and password are valid', async ({ page }) => {
  await page.goto(APP_URL);

  const emailInput = page.getByLabel('Email');
  const passwordInput = page.getByLabel('Password');
  const loginButton = page.getByRole('button', { name: 'Log in' });

  await emailInput.fill('not-an-email');
  await passwordInput.fill('password123');
  await expect(loginButton).toBeDisabled();

  await emailInput.fill('test@example.com');
  await expect(loginButton).toBeEnabled();
});

test('shows an error for invalid credentials', async ({ page }) => {
  await page.goto(APP_URL);

  await page.getByLabel('Email').fill('invalid-user@example.com');
  await page.getByLabel('Password').fill('wrong-password');
  await page.getByRole('button', { name: 'Log in' }).click();

  await expect(page.locator('.login-error')).toBeVisible({ timeout: 15000 });
});
