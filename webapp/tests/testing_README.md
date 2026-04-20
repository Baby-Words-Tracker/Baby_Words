# Testing README

Run these commands from:

`\wordbuds\Baby_Words\webapp`

## 1) Install dependencies

```powershell
npm install
```

## 2) Build check (recommended)

```powershell
npm run build
```

## 3) Angular unit tests (Karma)

```powershell
npm test
```

## 4) Playwright tests

Install browsers (first time only):

```powershell
npx playwright install
```

Start the app in one terminal:

```powershell
npm run start -- --host 127.0.0.1 --port 4200
```

In a second terminal, run all Playwright tests:

```powershell
npx playwright test
```

## 5) Run only role-access tests (researcher/admin)

With the dev server still running on `http://127.0.0.1:4200`, run:

```powershell
npx playwright test tests/example.spec.ts --project=chromium --grep "researcher can only see researcher dashboard|admin can see all dashboard views"
```

## 6) Optional: run only the example spec

```powershell
npx playwright test tests/example.spec.ts --project=chromium
```
