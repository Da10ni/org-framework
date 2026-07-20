# Changelog

## v1.2.0 — Stack Profiles

### skills/stacks/ — Stack-specific conventions (25 new files)
Kisi aur ne add kiya — merged with our v1.1.6 fixes.

Pehle agent sirf generic skills follow karta tha — `core.md`, `security.md` etc.
Ab jab stack detect ho, agent us stack ka specific profile bhi padhe:

```
skills/stacks/
  README.md                     ← how profiles work, how to add new ones
  _TEMPLATE/                    ← template for adding new stacks
  backend/
    java-spring-boot/           ← conventions, security, testing, error-handling
    node-express/               ← conventions, security, testing, error-handling
    python-fastapi/             ← conventions, security, testing
  frontend/
    react/                      ← conventions, security, testing
    vue/                        ← conventions, security, testing
    angular/                    ← conventions, security, testing
```

### AGENT.md Section 4.1 — Stack-profile routing added
Stack resolve hone ke baad agent automatically matching
`skills/stacks/<layer>/<value>/` folder load karta hai. Polyglot
projects dono profiles load karte hain (e.g. react + java-spring-boot).
Missing profile → offer to create from `_TEMPLATE/`.

## v1.1.4

### sync.sh — Backend subfolder scan for monorepos
- **Gap:** `detect_stack()` only checked root-level files for backend markers.
  Projects using a monorepo layout with a dedicated `backend/`, `server/`, or
  `api/` subfolder had their backend reported as `none` or `node-js` because
  the actual marker files (`pom.xml`, `requirements.txt`, `go.mod`, etc.) were
  one level down.
- **Fix:** added a backend subfolder scan that runs after root-level detection
  and the express check, but only when backend is still `none` or `node-js`
  (i.e. root detection found nothing definitive). Scans `backend/`, `server/`,
  `api/` in that order and applies the same full detection logic as root level
  — Spring Boot, Maven, Gradle, FastAPI, Django, Flask, Go, Rust, Rails, Express.
  Purely additive — root-level detection is completely unchanged.
- **Tested** against six cases:
  - `frontend/react` + `backend/pom.xml` → `frontend=react, backend=java-spring-boot` ✓
  - `frontend/react` + `backend/requirements.txt` (Django) → `frontend=react, backend=python-django` ✓
  - `frontend/react` + `server/go.mod` → `frontend=react, backend=go` ✓
  - root `react+express` (regression) → `frontend=react, backend=node-express` ✓
  - root `pom.xml` only (regression) → `backend=java-spring-boot` ✓
  - root `pom.xml` + `requirements.txt` ambiguous (regression) → `AMBIGUOUS` ✓

## v1.1.3

### sync.sh — Ambiguous stack detection (conflict guard)
- **Bug:** when multiple backend markers were present simultaneously (e.g.
  `pom.xml` + `requirements.txt`), `detect_stack()` silently picked `pom.xml`
  by priority order and ignored the rest, never warning the developer.
- **Fix:** a conflict counter now runs before the main detection chain and counts
  how many distinct backend marker files are present (`pom.xml`, `build.gradle`,
  `requirements.txt`/`pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile`).
  `package.json` is excluded from the count because it legitimately coexists with
  any backend in a fullstack setup. If count > 1, `detect_stack()` emits
  `backend=AMBIGUOUS` and returns immediately. The PK instantiation block handles
  `AMBIGUOUS` by copying the template as-is with placeholders intact and printing
  a clear warning message instead of the normal "Detected:" line.

### sync.sh — Monorepo subfolder frontend detection
- **Gap:** `detect_stack()` only checked root-level `package.json` for frontend
  frameworks. Projects using the common monorepo pattern (`frontend/`, `client/`,
  `web/`, `app/` subfolders each with their own `package.json`) had their frontend
  reported as `node-js` or `none` because the framework files were in a subfolder
  the script never looked at.
- **Fix:** frontend detection now falls through to subfolders when root
  `package.json` contains no known framework. Detection order: (1) root
  `package.json` — if a known framework is found, done; (2) if root has no
  known framework, scan `frontend/`, `client/`, `web/`, `app/` in that order
  and use the first subfolder `package.json` that contains a known framework;
  (3) if nothing is found anywhere, fall back to `node-js` (root package.json
  present) or `none` (no package.json anywhere).
- **Tested** against six cases: root tooling-only + `frontend/react` → `react`;
  `pom.xml` + `frontend/react` → `frontend=react, backend=java-spring-boot`;
  root `react+express` → unchanged; `pom.xml` only → unchanged; no root pkg +
  `client/vue` + `requirements.txt/django` → `frontend=vue, backend=python-django`;
  ambiguous (`pom.xml` + `requirements.txt`) → `AMBIGUOUS`.

## v1.1.2 — Bugfix

### sync.sh — express not detected when a frontend framework is also present
- **Bug:** the express check inside `detect_stack()` was nested inside the
  condition `[[ -f "package.json" ]] && [[ "$frontend" == "none" ]]`. As soon
  as any frontend framework (react, vue, nextjs, angular, svelte) was detected,
  `$frontend` was no longer `"none"`, so the entire branch was skipped —
  leaving `backend=none` for any fullstack/monorepo project that declares both
  a frontend framework and express in the same `package.json`.
- **Fix:** the express check is now a standalone `if` block that runs after the
  main backend `elif` chain, gated only on `[[ "$backend" == "none" ]]` (no
  other backend file found yet) and `[[ -f "package.json" ]]` (the file is
  present). The `[[ "$frontend" == "none" ]]` guard is gone. A comment in the
  code explains why the guard was the bug and why it was removed.
- **Tested** against five cases:
  - react + express → `frontend=react, backend=node-express` ✓ (was the bug)
  - react only → `frontend=react, backend=node-js` ✓ (no regression)
  - express only → `frontend=node-js, backend=node-express` ✓ (no regression)
  - vue + express → `frontend=vue, backend=node-express` ✓ (new coverage)
  - pom.xml + package.json → `backend=java-spring-boot` (package.json fallback
    correctly blocked by `[[ "$backend" == "none" ]]`) ✓ (no regression)
- **Only file changed:** `sync.sh` lines 235–252. No other files touched.

## v1.1.1 — Bugfix

### sync.sh — sed delimiter crash on PROJECT_KNOWLEDGE.md auto-fill
- **Bug:** the five `sed -e` substitutions in the `PROJECT_KNOWLEDGE.md`
  auto-instantiation block used `|` as the sed delimiter, but the placeholder
  text (e.g. `[e.g. react-18 | vue-3 | none]`) itself contains literal `|`
  characters. sed treats each `|` inside the expression as a delimiter
  boundary, producing `unknown option to 's'` at char 31 and aborting with
  a non-zero exit. Every first sync of any new project would crash at this
  step, leaving `PROJECT_KNOWLEDGE.md` unwritten.
- **Fix:** changed all five sed delimiters from `|` to `@`. `@` is absent
  from all placeholder text and from all values `detect_stack()` can
  produce (verified: detected values are lowercase alphanumeric + hyphens,
  `none`, `unknown`, `N/A`, or the two known Django/FastAPI layout strings).
  A comment documenting the delimiter choice and the safety guarantee was
  added inline.
- **Tested against real template output** for: Java+Spring Boot+Postgres+Docker,
  Node+React+MongoDB+Vercel, Python+Django+Postgres+Docker, bare project
  (all none/unknown). All four cases produce clean stack blocks with no
  leftover brackets and no sed errors.
- **Only file changed:** `sync.sh` lines 307–319. No other files touched.

## v1.1.0

### 1. Stronger Auto-Trigger
- `templates/CLAUDE.template.md`: added unconditional gate paragraph stating
  the gate fires on every session's first message with no exceptions based on
  content or phrasing; presence of `CLAUDE.md` is itself the trigger.
- `AGENT.md` Section 1: rewrote trigger language — gate is now declared
  unconditional; removed the loophole that allowed trivial first messages to
  bypass substantive-output requirements. No existing rules removed or weakened.

### 2. Auto Stack Detection (priority reversal)
- `AGENT.md` Section 4.2: reversed routing priority — agent now auto-detects
  stack from project files first (`pom.xml`, `package.json`, `requirements.txt`,
  `go.mod`, etc.); declared `stack:` block is now "reference/override," not
  primary source of truth. Conflict safeguard retained: ambiguous signals → agent
  must ask, never guess.
- `templates/PROJECT_KNOWLEDGE.template.md`: updated `stack:` block heading and
  comment to reflect "reference/override" semantics.
- `sync.sh`: `detect_stack()` function added; `PROJECT_KNOWLEDGE.md` is now
  auto-instantiated on first sync with the detected stack pre-filled.

### 3. Language Matching (script consistency, not forced Roman Urdu)
- `skills/language-agnostic-behavior.md`: added Section 1a "Conversational
  Language Matching" — agent mirrors user's natural language mix in conversation;
  hard constraint: Latin script only regardless of vocabulary origin. Main rule
  (Section 1) governing produced artifacts is unchanged.

### 4. Close the student-api Gap
- `sync.sh`: added auto-instantiation of `PROJECT_KNOWLEDGE.md` and `DECISIONS.md`
  on first sync (parallel to existing `CLAUDE.md` logic); `PROJECT_KNOWLEDGE.md`
  is created with detected stack pre-filled rather than left as bare placeholders.
- `AGENT.md` Section 4.2: added "Proactive gap-fix at session start" rule — agent
  must offer to fix foundational gaps in the same turn rather than just flagging.

### 5. Native CLI / Slash Commands at Repo Root
- `templates/dot-claude-commands/build.md` (new): thin wrapper for `/build`.
- `templates/dot-claude-commands/decide.md` (new): thin wrapper for `/decide`.
- `templates/dot-claude-commands/review.md` (new): thin wrapper for `/review`.
- `templates/dot-claude-commands/test.md` (new): thin wrapper for `/test`.
- `sync.sh`: added `.claude/commands/` creation block — populates native slash
  command wrappers in the consumer repo on first sync, parallel to existing
  `.framework/commands/` (which remains unchanged and unaffected).
- `AGENT.md` Section 5: documented both command layers, wrapper format, and
  backward-compatibility guarantee for tools that don't support `.claude/commands/`.

## v1.0.0 — Initial Release

- Core framework structure established: agents/, commands/, skills/
- 11 skill files covering universal engineering principles (core, architecture,
  error-handling, api-design, security, testing, code-review,
  technology-handling, dependency-management, performance,
  language-agnostic-behavior)
- 4 agent personas: builder, reviewer, tester, architect
- 4 commands: build, review, test, decide
- PROJECT_KNOWLEDGE.md and DECISIONS.md templates
- sync.sh vendoring script for consumer repos
- AGENT.md master bootstrap file
