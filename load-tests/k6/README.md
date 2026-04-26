# HabitDuel k6 Load Tests

This folder contains backend API load tests for the local Docker Compose stack.

## Scripts

- `api-smoke.js`: quick availability check for the main routes.
- `api-lifecycle.js`: full two-player duel flow with registration, login, duel creation, accept, check-in, details, and leaderboard.
- `api-load.js`: mixed load scenario that creates real test users, runs duel lifecycles, and browses authenticated API routes.

## Covered Routes

- `GET /healthz`
- `POST /auth/register`
- `POST /auth/login`
- `GET /users/me`
- `POST /duels/`
- `GET /duels/`
- `GET /duels/:id`
- `POST /duels/:id/accept`
- `POST /duels/:id/checkin`
- `GET /leaderboard/`

## Quick Run

```powershell
docker compose up -d --build db migrate server
docker compose --profile load run --rm k6
```

By default, Docker Compose runs `api-load.js`.

## Choose A Script

```powershell
$env:K6_SCRIPT="api-smoke.js"
docker compose --profile load run --rm k6
```

```powershell
$env:K6_SCRIPT="api-lifecycle.js"
$env:K6_VUS="10"
$env:K6_DURATION="20s"
docker compose --profile load run --rm k6
```

## Main Load Profile

```powershell
$env:K6_SCRIPT="api-load.js"
$env:K6_RUN_ID="main-load-01"
$env:K6_AUTH_VUS="8"
$env:K6_DUEL_VUS="20"
$env:K6_BROWSE_RATE="25"
$env:K6_BROWSE_VUS="40"
$env:K6_PAIR_COUNT="60"
$env:K6_RAMP_UP="1m"
$env:K6_STEADY="4m"
$env:K6_RAMP_DOWN="1m"
docker compose --profile load run --rm k6
```

## Stress Profile

```powershell
$env:K6_SCRIPT="api-load.js"
$env:K6_RUN_ID="stress-01"
$env:K6_AUTH_VUS="20"
$env:K6_DUEL_VUS="50"
$env:K6_BROWSE_RATE="80"
$env:K6_BROWSE_VUS="120"
$env:K6_PAIR_COUNT="180"
$env:K6_RAMP_UP="2m"
$env:K6_STEADY="8m"
$env:K6_RAMP_DOWN="2m"
docker compose --profile load run --rm k6
```

## Notes

- `K6_RUN_ID` keeps generated test users grouped by run.
- These tests target the Shelf + PostgreSQL API.
- Firebase Auth, Firestore, FCM, and Flutter-only UI flows should be tested separately.
