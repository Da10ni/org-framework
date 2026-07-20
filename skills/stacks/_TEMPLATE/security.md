# [Stack Name] — Security

**Applies when** the resolved [backend|frontend] stack is
`[exact-identifier]`. Stack-specific expression of `skills/security.md` —
implements its principles, never relaxes them.

[For each relevant `security.md` principle, state the stack-specific
*how*. Be concrete — this is the file most likely to prevent a real
vulnerability. Suggested coverage:]

## Authn / authz
[Which library/mechanism enforces authentication and authorization; how
object-level (IDOR) checks are done (`security.md` 3.3); where the
permission check is centralized (`security.md` 3.2).]

## Input, headers, rate limiting
[Boundary validation mechanism / allow-list (`security.md` 5.1); how
security headers and CSRF are wired (`security.md` 8); how rate limiting
is added for auth endpoints (`security.md` §6).]

## Secrets & data access
[How secrets are sourced (`security.md` 4.1); parameterized queries /
output encoding (`security.md` 5.2); how internal detail is kept out of
client-facing errors (`security.md` 5.3).]

> Frontend note: the client is never the security boundary — the server
> re-validates and re-authorizes everything (`security.md` 3.1). Delete
> this note for a backend stack.
