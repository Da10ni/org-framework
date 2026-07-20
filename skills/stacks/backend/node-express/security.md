# Node.js / Express — Security

**Applies when** the resolved backend stack is `node-express`.
Stack-specific expression of `skills/security.md` — implements its
principles, never relaxes them.

## Headers, rate limiting, CORS
- **`helmet`** for security headers (CSP, HSTS, etc.), mounted once as
  app-level middleware — `security.md` 8.2. Don't hand-roll headers.
- **`express-rate-limit`** (or a gateway limit) on auth and other
  sensitive endpoints — Express ships no throttling; unthrottled login
  violates `security.md` §6.
- **CORS** configured with an explicit allow-list of origins — never
  `origin: true` / `*` on an authenticated API (`security.md` 8.3 context).

## Authn / authz
- Enforced in dedicated middleware applied at the route, and **re-checked
  at object level** (`security.md` 3.3, IDOR) — never trust an `id` in the
  params just because the caller is authenticated.
- Centralize the permission check (`security.md` 3.2), don't reimplement
  per route.
- Passwords hashed with `bcrypt`/`argon2` — never a fast hash. Generic
  failure message on bad login (`security.md` 2.3).
- Session cookies: `HttpOnly`, `Secure`, `SameSite` (`security.md` 7.3);
  regenerate the session id on login (`security.md` 7.1).

## Secrets & input
- Secrets from `process.env` (`dotenv` in dev, real env/secret manager in
  prod); `.env` git-ignored, committed `.env.example` holds placeholders
  only (`security.md` 4.1).
- Validate every body/query/param at the boundary with a schema validator
  (`zod`, `joi`, `express-validator`) — allow-list landing point for
  `security.md` 5.1; reject before any logic runs.
- Parameterized queries / ORM query builder, never string-concatenated
  SQL/NoSQL (`security.md` 5.2). Pick allowed body fields explicitly —
  don't spread `req.body` onto a model (mass-assignment, `security.md` 10.3).
