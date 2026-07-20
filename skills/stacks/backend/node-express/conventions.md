# Node.js / Express — Conventions

**Applies when** the resolved backend stack is `node-express` (consult for
`node-js` where Express is the web layer).
**Style guide:** no single official one; common baseline is
[Airbnb JavaScript](https://github.com/airbnb/javascript) via ESLint +
Prettier. The project's `.eslintrc`/`prettier` config is authoritative
where present and recorded in `PROJECT_KNOWLEDGE.md`.

> Stack-specific *expression* of the generic principles — never relaxes
> them. On conflict the generic `skills/*.md` file wins. See
> `skills/stacks/README.md`.

## Naming & casing (expresses `core.md` §2)
- Variables/functions `camelCase`; classes/constructors `PascalCase`;
  module constants `UPPER_SNAKE_CASE`.
- Filenames: one convention per project — `kebab-case` (`user-service.js`)
  is the common default. Consistency (`core.md` 2.6) matters more than
  which; record the choice in `PROJECT_KNOWLEDGE.md`.
- Booleans/predicates read as questions (`isActive`, `hasAccess`).
- Prefer `async`/`await` over callbacks or long `.then()` chains
  (`technology-handling.md` 2.1).

## Project layout
Layered, feature-grouped once beyond trivial size:

```
src/
  routes/        # express.Router() per feature — HTTP mapping only
  controllers/   # request handlers, thin
  services/      # business logic — NO req/res objects here
  repositories/  # data access
  middleware/    # auth, validation, error handler
  models/        # schema / ORM models
  config/        # env loading; no secrets committed
app.js|server.js # wiring + listen
```

- Keep `req`/`res` out of the service layer — controllers translate HTTP
  to/from plain arguments; services stay transport-agnostic and testable.

## Gotchas
- Blocking the event loop with sync CPU work (`fs.*Sync`, crypto in a
  loop, huge JSON) stalls all concurrent requests — use async APIs / offload.
- Behind a proxy, set `app.set('trust proxy', ...)` or rate-limiting and
  client-IP logging see the proxy IP, not the real client.
