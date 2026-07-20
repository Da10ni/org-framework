# Angular — Testing

**Applies when** the resolved frontend stack is `angular`.
Stack-specific expression of `skills/testing.md`.

- **Jasmine + Karma** is the Angular default; many teams move to **Jest**
  — use whichever the project declares in `PROJECT_KNOWLEDGE.md`.
  **Playwright** or **Cypress** for end-to-end.
- Use **`TestBed`** to configure the testing module; test **observable
  behavior** (rendered output, emitted outputs, service calls), not
  private implementation details.
- Prefer **Testing Library for Angular** where adopted — query by
  role/text so tests survive refactors rather than binding to internal
  structure.
- Mock HTTP with `HttpClientTestingModule` / `HttpTestingController` at
  the boundary rather than stubbing services ad hoc.
- Test files `*.spec.ts` colocated with the unit under test.
- Cover loading, empty, and error states — not just the populated happy
  path.
