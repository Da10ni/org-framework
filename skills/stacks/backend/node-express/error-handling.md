# Node.js / Express — Error Handling

**Applies when** the resolved backend stack is `node-express`.
Stack-specific expression of `core.md` §5 + `skills/error-handling.md`.

- A **centralized error-handling middleware** — the 4-arg
  `(err, req, res, next)` signature — is the single boundary that shapes
  error responses. Align the shape with `error-handling.md` and record it
  in `PROJECT_KNOWLEDGE.md`. No ad-hoc error bodies per route.
- In `async` route handlers, forward errors with `next(err)` or wrap with
  an `asyncHandler` / `express-async-errors`. An unawaited rejection that
  escapes the handler hangs the request or crashes the process — this is
  where `core.md` 5.1 (fail loud, never swallow) lands in Node.
- Never `catch (e) {}` or catch-log-continue at a boundary.
- Distinguish **operational** errors (recoverable — bad input, upstream
  timeout) from **programmer** errors (bugs) per `core.md` 5.3; do not keep
  the process limping after an unrecoverable error.
- Expected-miss lookups return `null`/`undefined` or an empty array
  (`core.md` 5.4); throw only where a miss becomes a boundary decision
  (e.g. a 404). Don't use thrown errors for normal control flow.
- Production error responses are generic — no stack trace, internal path,
  or DB error string to the client (`security.md` 5.3).
