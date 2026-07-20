# React — Testing

**Applies when** the resolved frontend stack is `react`.
Stack-specific expression of `skills/testing.md`.

- **Vitest** or **Jest** + **React Testing Library**; **Playwright** or
  **Cypress** for end-to-end.
- Test **behavior the user observes**, not implementation details — query
  by role/text (`getByRole`, `getByText`), not by internal class names or
  component internals. This keeps tests resilient to refactors.
- Mock network at the boundary (e.g. MSW) rather than stubbing fetch
  ad hoc; assert on rendered output and user interactions.
- Test files `*.test.tsx` / `*.spec.tsx`, colocated with the component or
  under `__tests__/` — one convention per project.
- Cover loading, empty, and error states — not just the populated happy
  path.
