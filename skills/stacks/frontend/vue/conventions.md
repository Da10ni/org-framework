# Vue — Conventions

**Applies when** the resolved frontend stack is `vue`.
**Style guide:** the [official Vue Style Guide](https://vuejs.org/style-guide/)
(Priority A/B rules are effectively mandatory) + ESLint (`eslint-plugin-vue`)
+ Prettier. Project config is authoritative and recorded in
`PROJECT_KNOWLEDGE.md`.

> Stack-specific *expression* of the generic principles — never relaxes
> them. On conflict the generic `skills/*.md` file wins. See
> `skills/stacks/README.md`.

## Naming & casing (expresses `core.md` §2)
- Component files `PascalCase` (`UserCard.vue`); multi-word component
  names always (Vue style guide, avoids clashing with HTML elements).
- Props declared in `camelCase`, used in templates as `kebab-case`.
- Composables `useXxx`. Booleans read as predicates (`isOpen`, `hasError`).
- Prefer **Composition API** with `<script setup>` for new components;
  match the existing codebase where it standardized on Options API
  (`technology-handling.md` 3.1).

## Project layout
Feature-grouped:

```
src/
  features/<feature>/    # components, composables, api for one feature
  components/            # shared, reusable UI
  composables/           # shared composition functions
  stores/                # Pinia stores (state management)
  services/ | lib/       # api clients, utilities
  App.vue | main.ts
```

## Idiomatic rules
- **Pinia** for shared state (the current standard over Vuex) — declared
  in `PROJECT_KNOWLEDGE.md`; don't introduce a second state pattern
  (`technology-handling.md` 3.1).
- Keep components focused; extract reusable stateful logic into a
  composable rather than duplicating it.
- Prefer TypeScript; type props (`defineProps<T>()`) and emits. Avoid
  `any` to silence real type errors.

## Gotchas
- Directly mutating a prop breaks one-way data flow — emit an event or use
  a local copy.
- Losing reactivity by destructuring a reactive object without `toRefs` /
  `storeToRefs` is a common Composition-API trap.
