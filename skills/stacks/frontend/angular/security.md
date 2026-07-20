# Angular — Security

**Applies when** the resolved frontend stack is `angular`.
Stack-specific expression of `skills/security.md`. The client is never the
security boundary — the server re-validates and re-authorizes everything
(`security.md` 3.1). These rules reduce client-side risk on top of that.

- **XSS:** Angular sanitizes interpolation and `[innerHTML]` bindings by
  default. Never defeat that with `bypassSecurityTrust*` on untrusted
  content — if raw HTML is unavoidable, sanitize with `DomSanitizer` and
  treat `bypassSecurityTrust*` as a red flag requiring justification
  (`security.md` 5.2).
- **Auth token handling:** attach tokens via an `HttpInterceptor` (one
  place), not per-call. Prefer server-set `HttpOnly` cookies over
  `localStorage` for session tokens (readable by injected script).
- **Route guards are UX, not enforcement** (`security.md` 3.1):
  `canActivate`/`canMatch` guards improve experience; every protected
  action is authorized again server-side.
- **No secrets in the bundle:** `environment.ts` values are compiled into
  the public build — never put real secrets/private API keys there
  (`core.md` 6.1); only publishable config.
- **Untrusted URLs:** validate user-derived `href`/`routerLink`/redirect
  targets; avoid `javascript:` URLs and open-redirect sinks.
- **CSRF:** when using cookie auth, use Angular `HttpClient`'s built-in
  `XSRF` token support (`HttpClientXsrfModule` / `withXsrfConfiguration`)
  aligned with the server (`security.md` 8.3).
- **Dependencies:** `npm audit` on the declared cadence (`security.md`
  6.4 / `dependency-management.md`).
