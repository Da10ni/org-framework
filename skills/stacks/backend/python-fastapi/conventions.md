# Python / FastAPI — Conventions

**Applies when** the resolved backend stack is `python-fastapi`.
**Style guide:** [PEP 8](https://peps.python.org/pep-0008/) enforced via
`ruff`/`black`; type hints per PEP 484. Project `pyproject.toml` tool
config is authoritative and recorded in `PROJECT_KNOWLEDGE.md`.

> Stack-specific *expression* of the generic principles — never relaxes
> them. On conflict the generic `skills/*.md` file wins. See
> `skills/stacks/README.md`.

## Naming & casing (expresses `core.md` §2)
- Functions/variables/modules `snake_case`; classes `PascalCase`;
  constants `UPPER_SNAKE_CASE`. Files/modules `snake_case.py`.
- No Java-style getter/setter boilerplate — use plain attributes and,
  where computed access is needed, `@property` (`technology-handling.md`
  2.1). Booleans read as predicates (`is_active`, `has_access`).

## Project layout
Router-based layout (the FastAPI-idiomatic of the two common Python
conventions — declared in `PROJECT_KNOWLEDGE.md` per `technology-handling.md` 2.3):

```
app/
  api/routers/       # APIRouter per feature — HTTP mapping only
  services/          # business logic
  repositories/      # data access
  schemas/           # Pydantic models (request/response)
  models/            # ORM models (SQLAlchemy etc.)
  core/              # config, security, dependencies
  main.py            # app factory + router wiring
```

## Idiomatic rules
- Use FastAPI **dependency injection** (`Depends(...)`) for shared
  concerns (DB session, current user, pagination) — not module globals.
- **Pydantic** models are the request/response schema; keep them separate
  from ORM models — never return an ORM object directly.
- Use `async def` handlers with async DB drivers; don't mix a sync
  blocking driver into an async path (blocks the event loop).

## Gotchas
- A blocking call (sync DB driver, `requests`, `time.sleep`) inside an
  `async def` stalls the whole event loop — use async libraries or
  `run_in_executor`.
- Mutable default arguments (`def f(x=[])`) are a classic Python trap —
  default to `None` and construct inside.
