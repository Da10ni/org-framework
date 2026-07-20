# Spring Boot — Security

**Applies when** the resolved backend stack is `java-spring-boot`.
Stack-specific expression of `skills/security.md` — implements its
principles, never relaxes them.

## Authn / authz
- **Spring Security** is the single place the auth strategy is configured
  (`SecurityFilterChain` bean) — satisfies `security.md` 2.1 ("decided
  once"). Don't roll a custom filter where Spring Security covers it.
- Object-level authorization (`security.md` 3.3, IDOR) via method
  security — `@PreAuthorize("@authz.canAccess(#id, principal)")` or an
  explicit ownership check in the service. Never assume a logged-in user
  may touch any `id` they pass.
- Centralize permission logic in one policy bean per resource type
  (`security.md` 3.2), not reimplemented per endpoint.

## Passwords & sessions
- `BCryptPasswordEncoder` (or Argon2) — never plaintext or a fast hash.
- Generic failure message on bad login (`security.md` 2.3) — don't reveal
  whether username or password was wrong.
- On login/privilege change, Spring Security rotates the session id by
  default (session-fixation protection) — don't disable it
  (`security.md` 7.1).

## Headers, CSRF, rate limiting
- CSRF is **on by default** for session-cookie apps — do not blanket-
  disable it (`security.md` 8.3). For a stateless token API, disable
  deliberately and document why.
- Security headers via Spring Security's `headers()` DSL (CSP, HSTS,
  frame options) — `security.md` 8.2.
- Rate limiting (`security.md` §6) is **not** built in — wire Bucket4j or
  a gateway limit on auth endpoints; never leave login unthrottled.

## Secrets & input
- Secrets from env/`application.yml` placeholders backed by env vars or a
  secrets manager — never hardcoded, never in a committed populated
  `application-local.yml` (`security.md` 4.1).
- Validate request bodies with Bean Validation (`@Valid` +
  `jakarta.validation` annotations) — the allow-list landing point for
  `security.md` 5.1. Bind only permitted DTO fields (mass-assignment
  defense, `security.md` 10.3).
