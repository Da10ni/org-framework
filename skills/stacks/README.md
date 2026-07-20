# Stack Profiles (`skills/stacks/`)

This directory holds **stack profiles** — the concrete, stack-specific
conventions the agent applies once a project's stack is resolved. The
generic files at `skills/` root (`core.md`, `security.md`, etc.) are
stack-agnostic principle; these folders are where "the standard for
*this* stack" actually lives.

The mechanism is defined normatively in `skills/technology-handling.md`
Section 6 and routed from `AGENT.md` Section 4.1 / Section 4.2. This
README is the operational how-to.

---

## 1. Layout — one folder per stack, grouped by layer

```
skills/stacks/
  <layer>/                     # backend | frontend
    <detected-value>/          # exact identifier detect_stack() emits
      conventions.md           # naming, layout, idiomatic rules, gotchas
      security.md              # stack-specific wiring of skills/security.md
      testing.md               # stack-specific wiring of skills/testing.md
      error-handling.md        # (backend) wiring of skills/error-handling.md
```

Shipped profiles:

```
skills/stacks/
  backend/
    java-spring-boot/   conventions · security · testing · error-handling
    node-express/       conventions · security · testing · error-handling
    python-fastapi/     conventions · security · testing
  frontend/
    react/              conventions · security · testing
    vue/                conventions · security · testing
    angular/            conventions · security · testing
```

## 2. How a profile is selected

At session start the agent resolves the stack per `AGENT.md` Section 4.2
(auto-detect from project files first; `PROJECT_KNOWLEDGE.md`'s `stack:`
block refines or overrides). It then loads the folder whose path matches
the resolved values, using the **same identifiers `detect_stack()`
emits** for the folder name:

| Resolved value (`detect_stack`) | Profile folder                         |
|---------------------------------|----------------------------------------|
| backend `java-spring-boot`      | `backend/java-spring-boot/`            |
| backend `node-express`          | `backend/node-express/`               |
| backend `python-fastapi`        | `backend/python-fastapi/`             |
| frontend `react`                | `frontend/react/`                     |
| frontend `vue`                  | `frontend/vue/`                       |
| frontend `angular`              | `frontend/angular/`                   |

> Note: a Gradle-based Spring Boot project resolves to `java-spring-boot`
> (not `java-gradle`) — `detect_stack()` checks for Spring Boot in
> `build.gradle`/`build.gradle.kts` as well as `pom.xml`, so both Maven
> and Gradle Spring Boot projects load the `backend/java-spring-boot/`
> profile.

A **polyglot project loads more than one profile** — e.g. `frontend=react`
+ `backend=java-spring-boot` loads both folders. Within a folder, the
agent loads the file(s) relevant to the task (e.g. `security.md` when the
work touches auth), not necessarily all four every time.

## 3. What a profile does and does not own

A profile is the stack-specific **expression** of the framework's generic
principles — never a replacement, never a place to relax them.

- **Generic files own the principle.** `core.md` owns *what a name
  communicates*; `security.md` owns *that authorization is checked at
  every access*.
- **The profile owns the stack-specific "how."** Casing, layout, which
  library enforces the check, the idiomatic error type.

A profile that **contradicts** a generic file is a defect, resolved in the
generic file's favor — unless a deliberate divergence is logged in
`DECISIONS.md`. A profile never lowers `core.md` Section 7's checklist bar.

## 4. Adding a new stack profile

Profiles are populated **from real use, not speculatively** (`AGENT.md`
Section 7). Don't pre-write a profile for a stack no consuming project uses.

When a project first uses a stack with no folder yet:

1. Copy `_TEMPLATE/` to `skills/stacks/<layer>/<detected-value>/`, using
   the exact identifier `detect_stack()` emits.
2. Fill each file from the stack's **official style guide** — cite it,
   don't invent conventions. Drop `error-handling.md` for a pure frontend
   stack; mark any genuinely inapplicable section "N/A for this stack."
3. A profile is a standing convention — if it diverges from a framework
   default, log that divergence in `DECISIONS.md` (foundational-tier).

The agent should **offer to create a missing profile in the same turn** it
detects the gap, not silently proceed on generic principles only (same
posture as `AGENT.md` Section 4.2's proactive gap-fix).
