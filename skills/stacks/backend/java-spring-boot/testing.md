# Spring Boot — Testing

**Applies when** the resolved backend stack is `java-spring-boot`.
Stack-specific expression of `skills/testing.md`.

- **JUnit 5** (`org.junit.jupiter`) + **Mockito** for unit tests; AssertJ
  for fluent assertions is common.
- Slice tests over full-context where possible: `@WebMvcTest` (controller
  layer), `@DataJpaTest` (persistence). Use `@SpringBootTest` only when a
  test genuinely needs the full context.
- **Naming convention** (drives Maven surefire vs. failsafe):
  `FooTest` = unit (surefire), `FooIT` = integration (failsafe).
- Use **Testcontainers** for tests needing a real database rather than an
  in-memory substitute (e.g. H2) that diverges from production behavior.
- Mock external I/O at the boundary; test business logic in the service
  layer without standing up HTTP or a DB where not needed.
- Cover the failure paths defined in `error-handling.md`, not just the
  happy path — a `@RestControllerAdvice` mapping is behavior and gets a
  test.
