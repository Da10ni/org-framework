# React — Security

**Applies when** the resolved frontend stack is `react`.
Stack-specific expression of `skills/security.md`. Note: the client is
never the security boundary — the server re-validates and re-authorizes
everything (`security.md` 3.1). These rules reduce client-side risk on top
of that, they don't replace server-side controls.

- **XSS:** JSX escapes by default — never bypass it with
  `dangerouslySetInnerHTML` on untrusted content. If HTML rendering is
  unavoidable, sanitize with a vetted library (e.g. DOMPurify) first
  (`security.md` 5.2, output encoding).
- **Tokens:** prefer `HttpOnly` cookies (set by the server) for session
  tokens over `localStorage`, which is readable by any injected script.
  If tokens must live in JS, treat XSS as game-over and harden accordingly.
- **No secrets in the bundle:** anything in the frontend build is public.
  API keys/secrets never ship in client code or `VITE_`/`REACT_APP_`
  vars that are truly secret (`core.md` 6.1). Only publishable keys belong
  client-side.
- **Client-side auth is UX, not enforcement** (`security.md` 3.1): route
  guards and hidden buttons improve experience but every protected action
  is authorized again server-side.
- **Untrusted URLs:** validate `href`/redirect targets derived from user
  input; avoid `javascript:` URLs and open-redirect sinks.
- **Dependencies:** the npm supply chain is a real attack surface — `npm
  audit` on the declared cadence (`security.md` 6.4 /
  `dependency-management.md`).
