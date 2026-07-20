# Python / FastAPI — Security

**Applies when** the resolved backend stack is `python-fastapi`.
Stack-specific expression of `skills/security.md` — implements its
principles, never relaxes them.

## Authn / authz
- Auth enforced via a **dependency** (`Depends(get_current_user)`) applied
  to routers/routes — the single place the strategy lives (`security.md`
  2.1). OAuth2 password/bearer flows use `fastapi.security` utilities.
- Object-level authorization (`security.md` 3.3, IDOR) is an explicit
  ownership/permission check in the service or a dependency — never assume
  a user may access any `id` they pass.
- Centralize permission logic (`security.md` 3.2), don't reimplement per
  route.
- Passwords hashed with `passlib` (`bcrypt`/`argon2`) — never a fast hash.
  Generic failure message on bad login (`security.md` 2.3).

## Input, headers, rate limiting
- **Pydantic** models validate request bodies at the boundary — the
  allow-list landing point for `security.md` 5.1. Only declared fields are
  accepted; extras rejected/ignored (mass-assignment defense,
  `security.md` 10.3).
- Rate limiting (`security.md` §6) is not built in — use `slowapi` or a
  gateway limit on auth endpoints; never leave login unthrottled.
- Security headers / HTTPS redirect via middleware
  (`starlette` middlewares, `TrustedHostMiddleware`, a headers middleware)
  — `security.md` 8.1/8.2. Configure CORS with an explicit origin
  allow-list, never `*` on an authenticated API.

## Secrets & data access
- Secrets from environment via `pydantic-settings` (`BaseSettings`) —
  never hardcoded, never in a committed populated `.env` (`security.md`
  4.1); `.env` git-ignored, `.env.example` placeholders only.
- Use the ORM / parameterized queries — never f-string/`%`-formatted SQL
  (`security.md` 5.2).
- Don't leak internals: set a generic handler so tracebacks/DB errors
  don't reach the client in production (`security.md` 5.3); disable
  interactive debug in production.
