# Vue — Security

**Applies when** the resolved frontend stack is `vue`.
Stack-specific expression of `skills/security.md`. The client is never the
security boundary — the server re-validates and re-authorizes everything
(`security.md` 3.1). These rules reduce client-side risk on top of that.

- **XSS:** Vue escapes `{{ }}` interpolation by default — never bind
  untrusted content with `v-html`. If unavoidable, sanitize with a vetted
  library (e.g. DOMPurify) first (`security.md` 5.2).
- **Tokens:** prefer server-set `HttpOnly` cookies over `localStorage`
  for session tokens (readable by injected script).
- **No secrets in the bundle:** anything in the build is public. Secrets /
  private API keys never ship in client code or `VITE_` env vars
  (`core.md` 6.1) — only publishable keys.
- **Client-side guards are UX, not enforcement** (`security.md` 3.1):
  `router.beforeEach` guards improve experience; every protected action is
  authorized again server-side.
- **Untrusted URLs:** validate user-derived `:href`/redirect targets;
  avoid `javascript:` URLs and open-redirect sinks.
- **Dependencies:** `npm audit` on the declared cadence (`security.md`
  6.4 / `dependency-management.md`).
