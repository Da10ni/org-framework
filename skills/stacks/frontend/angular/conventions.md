# Angular — Conventions

**Applies when** the resolved frontend stack is `angular`.
**Style guide:** the [official Angular Style Guide](https://angular.dev/style-guide)
+ ESLint (`angular-eslint`) + Prettier. Project config is authoritative
and recorded in `PROJECT_KNOWLEDGE.md`.

> Stack-specific *expression* of the generic principles — never relaxes
> them. On conflict the generic `skills/*.md` file wins unless a
> `DECISIONS.md` entry records a deliberate divergence. See
> `skills/stacks/README.md`.

## Naming & casing (expresses `core.md` §2)
- File names use the Angular type-suffix convention:
  `user-card.component.ts`, `auth.service.ts`, `auth.guard.ts`,
  `user.model.ts` — `kebab-case` filename + `.type.ts`.
- Class names `PascalCase` with matching suffix (`UserCardComponent`,
  `AuthService`). Component selectors `kebab-case` with a project prefix
  (`app-user-card`).
- Booleans/predicates read as questions (`isActive`, `hasAccess`);
  observables conventionally suffixed `$` (`users$`).

## Project layout
Feature-grouped, with `core` (singletons) and `shared` (reusable):

```
src/app/
  core/            # singleton services, guards, interceptors (provided once)
  shared/          # reusable components, pipes, directives
  features/<feature>/
    <feature>.component.ts|html|scss
    <feature>.service.ts
    <feature>.routes.ts
  app.config.ts | app.routes.ts
```

## Idiomatic rules
- Prefer **standalone components** + `provideX()` APIs (current Angular
  direction) for new code; match the existing codebase if it standardized
  on NgModules (`technology-handling.md` 3.1 — don't mix a second pattern).
- **Constructor DI** with `inject()` or constructor params; services
  `@Injectable({ providedIn: 'root' })` for app-wide singletons.
- **RxJS:** use the `async` pipe in templates rather than manual
  `subscribe()`; where a manual subscription is unavoidable, unsubscribe
  (`takeUntilDestroyed`, `DestroyRef`). Never nest `subscribe()` inside
  `subscribe()` — compose with `switchMap`/`mergeMap`.
- Prefer TypeScript strictness; type inputs/outputs and API responses.
  Avoid `any` to silence real type errors.

## Gotchas
- Forgetting to unsubscribe a long-lived manual subscription leaks memory
  — prefer `async` pipe / `takeUntilDestroyed`.
- Heavy work in a getter bound in the template runs on every change-
  detection cycle — move it to a computed value / memoize.
- Mutating `@Input()` object references breaks `OnPush` change detection —
  emit changes via `@Output()` instead.
