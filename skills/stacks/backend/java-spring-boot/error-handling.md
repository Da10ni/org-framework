# Spring Boot — Error Handling

**Applies when** the resolved backend stack is `java-spring-boot`.
Stack-specific expression of `core.md` §5 + `skills/error-handling.md`.

- Boundary failures surface as **exceptions** — never swallowed
  (`core.md` 5.1). No `catch (Exception e) {}`, no catch-and-log without
  rethrow/handle.
- A single **`@RestControllerAdvice` / `@ExceptionHandler`** layer
  translates exceptions into one consistent error-response shape. Align
  the shape with `error-handling.md` and record it in
  `PROJECT_KNOWLEDGE.md` (Shared/Cross-Cutting). Do not build ad-hoc error
  bodies per controller.
- **Recoverable vs. unrecoverable** (`core.md` 5.3): custom domain
  exceptions extending `RuntimeException` for expected 4xx cases
  (`ResourceNotFoundException` → 404, `ValidationException` → 400); let
  genuinely unexpected failures propagate to a 500 with a **generic body**
  — never a stack trace to the client (`security.md` 5.3).
- **Expected miss** on a lookup returns `Optional<T>` at repository/service
  layer (`core.md` 5.4); the exception (→ 404) is thrown only at the
  boundary that decides a miss is an error — not for normal control flow.
- Validation errors from Bean Validation surface via
  `MethodArgumentNotValidException`; map them in the advice to a
  structured 400 listing the offending fields.
