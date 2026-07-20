# Spring Boot — Conventions

**Applies when** the resolved backend stack is `java-spring-boot`.
**Style guide:** [Google Java Style](https://google.github.io/styleguide/javaguide.html);
project `checkstyle`/`spotless` config, if present, is authoritative and
recorded in `PROJECT_KNOWLEDGE.md`.

> Stack-specific *expression* of the generic principles — never relaxes
> them. On conflict the generic `skills/*.md` file wins unless a
> `DECISIONS.md` entry records a deliberate divergence. See
> `skills/stacks/README.md`.

## Naming & casing (expresses `core.md` §2)
- Classes/interfaces/enums `PascalCase`; methods/fields `camelCase`;
  `static final` constants `UPPER_SNAKE_CASE` (where `core.md` 2.7 lands).
- Interfaces are **not** `I`-prefixed; name the interface for the concept
  (`PaymentService`), the impl `PaymentServiceImpl` only when a single
  obvious implementation exists.
- Packages: all-lowercase reverse-domain (`com.acme.billing.invoice`).
- Boolean accessors read as predicates: `isActive()`, `hasAccess()`.

## Project layout (expresses `technology-handling.md` 2.2/2.3)
Package-by-feature, not package-by-layer, beyond a trivial service:

```
src/main/java/com/acme/app/
  billing/                 # feature package
    BillingController.java  # thin: HTTP mapping + validation delegation
    BillingService.java     # business logic
    BillingRepository.java  # persistence
    dto/                    # request/response records
    domain/                 # entities / domain model
  config/                  # @Configuration classes
src/main/resources/
  application.yml           # prefer YAML; per-profile: application-<profile>.yml
```

## Idiomatic rules
- **Constructor injection** (`private final` + one constructor, no
  `@Autowired` needed) — never field injection (it hides dependencies and
  breaks test setup).
- Controllers stay thin; business logic in `@Service`; persistence in
  `@Repository`. No business logic in controllers or entities.
- Request/response bodies are dedicated DTOs (Java `record` types) —
  never expose JPA entities across the API boundary.

## Gotchas
- `@Transactional` on a private or self-invoked method silently does
  nothing (Spring proxies only external calls).
- Returning JPA entities from controllers → lazy-loading serialization
  errors and leaks the persistence model. Always map to a DTO.
