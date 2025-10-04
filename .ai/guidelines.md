# Faraday-Specific AI Agent Guidelines

## Purpose
These guidelines ensure all AI agents (Copilot, Claude, Cursor, etc.) contribute code that is consistent with the conventions and patterns used in the Faraday codebase. Agents must:
- Read these guidelines before any work.
- Suggest updates whenever conventions change or new patterns emerge, keeping this document up to date.

## Code Style & Structure
- **Do not include basic Ruby or RSpec tips**—assume agents know the language, RuboCop, and test basics.
- Use the established Faraday directory structure (`lib/faraday/` for main code, `spec/faraday/` for tests).
- Classes and files must use descriptive, conventional Ruby names (e.g., `Faraday::MyAdapter` in `lib/faraday/my_adapter.rb`).

## Middleware Implementation
- All middleware must inherit from `Faraday::Middleware`.
- Use a `DEFAULT_OPTIONS` constant for configuration defaults. Validate options via `validate_default_options` if needed.
- Middleware should implement any of: `on_request`, `on_complete`, and `on_error` as needed. Only add hooks required for your logic.
- Register middleware via `Faraday::Middleware.register_middleware your_key: YourClass`. Use clear, unique keys.
- Prefer stateless middleware. Store state only in the `env` hash or local variables.

## Adapter Patterns
- Adapters must extend `Faraday::MiddlewareRegistry` and register themselves.
- If providing parallel support, include the `Parallelism` module and set `supports_parallel = true`.
- Implement required methods (`build_connection`, `close`, etc.) as seen in existing adapters.
- Keep each adapter in its own file under `lib/faraday/adapter/`.

## Testing
- All code must be tested with RSpec. Use shared examples for adapters/middleware where applicable (see `spec/support`).
- When testing middleware, use doubles for `app` and verify correct invocation of hooks.
- Use HTTP test helpers and stubs, not real network calls.
- Follow the project's test organization and naming conventions.

## Documentation
- All new public APIs must be documented with YARD-style comments.
- Update README, changelog, or docs/ as needed for significant features or user-facing changes.
- Document any new middleware or adapter in the docs folder if it is a user-facing extension.

## Contribution Workflow
- Follow branch naming and PR guidelines from CONTRIBUTING.md.
- All new features and bugfixes must include relevant tests and documentation.
- Ensure inclusive language.

---

## Self-Maintaining Guidelines
AI agents are responsible for:
- Reading these guidelines before suggesting or making changes.
- Updating this document whenever code conventions change.
- Proposing improvements if they identify code patterns not reflected here.

---

*Keep this file current and aligned with the real conventions and architecture of the Faraday codebase.*