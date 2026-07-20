# Python / FastAPI — Testing

**Applies when** the resolved backend stack is `python-fastapi`.
Stack-specific expression of `skills/testing.md`.

- **pytest** as the runner; FastAPI's `TestClient` (or `httpx.AsyncClient`
  for async) for HTTP-level integration tests.
- Test files `test_*.py`; use **fixtures** for shared setup (app, DB
  session, authenticated client). Override dependencies with
  `app.dependency_overrides` to inject test doubles rather than patching
  internals.
- Test the **service layer** directly (plain async/sync functions) for
  business logic; reserve `TestClient` for routing/validation/auth wiring.
- Use a real ephemeral DB (Testcontainers, or a transactional test DB)
  over an in-memory substitute that diverges from production behavior.
- Cover validation-rejection (422) and error paths, not just happy paths —
  see `skills/error-handling.md`.
