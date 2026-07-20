# React — Conventions

**Applies when** the resolved frontend stack is `react`.
**Style guide:** [Airbnb React/JSX](https://github.com/airbnb/javascript/tree/master/react)
via ESLint + Prettier, plus the official React docs' guidance on hooks and
composition. Project `.eslintrc` is authoritative and recorded in
`PROJECT_KNOWLEDGE.md`.

> Stack-specific *expression* of the generic principles — never relaxes
> them. On conflict the generic `skills/*.md` file wins. See
> `skills/stacks/README.md`.

## Naming & casing (expresses `core.md` §2)
- Components `PascalCase` (`UserCard`); component files match the
  component name (`UserCard.tsx`). Hooks `useXxx` camelCase. Non-component
  helpers/vars `camelCase`; constants `UPPER_SNAKE_CASE`.
- Boolean props/state read as predicates (`isOpen`, `hasError`).
- Prefer function components + hooks; class components only in legacy code.

## Project layout
Feature-grouped, colocated:

```
src/
  features/<feature>/    # components, hooks, api, types for one feature
  components/            # shared, presentational, reusable UI
  hooks/                 # shared hooks
  lib/ | services/       # api clients, cross-cutting utilities
  App.tsx | main.tsx
```

## Idiomatic rules
- One responsibility per component; lift shared logic into a custom hook
  rather than duplicating it (the React expression of `technology-handling.md`
  3.1 — reuse the existing pattern).
- Keep components pure; side effects go in `useEffect`/event handlers with
  correct dependency arrays. Derive state, don't duplicate it.
- Prefer TypeScript; type props and API responses. Never use `any` to
  silence a real type error.
- Data fetching / server state through the project's chosen library
  (React Query / RTK Query / etc.) — declared in `PROJECT_KNOWLEDGE.md`,
  not a second ad-hoc pattern per component (`technology-handling.md` 3.1).

## Gotchas
- Missing/incorrect `useEffect` dependencies cause stale closures or
  infinite loops — don't disable the exhaustive-deps lint rule to hide it.
- Using array index as `key` in a reorderable list corrupts state — use a
  stable id.
