# Vue — Testing

**Applies when** the resolved frontend stack is `vue`.
Stack-specific expression of `skills/testing.md`.

- **Vitest** (Vite-native) + **Vue Test Utils** and/or **Testing Library
  for Vue**; **Playwright** or **Cypress** for end-to-end.
- Test **observable behavior** — query by role/text (Testing Library),
  not by internal component structure — so tests survive refactors.
- Mock network at the boundary (e.g. MSW); assert on rendered output and
  user interactions rather than internal state.
- Test files `*.test.ts` / `*.spec.ts`, colocated or under `__tests__/`.
- Cover loading, empty, and error states, not just the happy path.
