# Node.js / Express — Testing

**Applies when** the resolved backend stack is `node-express`.
Stack-specific expression of `skills/testing.md`.

- **Jest** or **Vitest** as the runner; **`supertest`** for HTTP-level
  integration tests against the Express app instance.
- Test files: `*.test.js` / `*.spec.js`, colocated or under `__tests__/`
  — hold one convention per project.
- Test the **service layer** directly (plain functions, no HTTP) for
  business logic; use `supertest` for route/middleware wiring.
- Mock external I/O (network, DB) at the boundary; prefer Testcontainers
  or an ephemeral DB over a divergent in-memory stub where fidelity matters.
- Cover the failure paths (error middleware, validation rejections), not
  just happy paths — see `error-handling.md`.
