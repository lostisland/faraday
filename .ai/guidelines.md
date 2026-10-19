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
- Use HTTP test helpers and stubs, not real network calls (the only exception is `spec/integration/`, see below).
- Follow the project's test organization and naming conventions.
- Run the unit tests with `bundle exec rake`: it excludes `spec/integration/`, which needs service containers.

### Integration Tests
Specs under `spec/integration/` exercise the Options classes (`RequestOptions`, `SSLOptions`, `ProxyOptions`, `ConnectionOptions`, `Env`) with real HTTP requests, to catch behavior changes when the options are refactored (see `docs/options-detach-plan.md`). Details for humans are in `.github/CONTRIBUTING.md`.
- One file per class in `spec/integration/options/<name>_integration_spec.rb`. Files in `spec/integration/` are automatically tagged `type: :integration`, which includes `Faraday::IntegrationHelpers` and disables WebMock. Never add `type: :integration` explicitly to the spec files.
- Run them with `bin/integration-tests [rspec args]` (needs Docker), which starts the same service containers as `.github/workflows/integration-tests.yml`. Specs that only need httpbin can run with `HTTPBIN_URL=... COVERAGE=false bundle exec rspec spec/integration`. `act` cannot run the workflow.
- Off-the-shelf servers run as **service containers** in the workflow's container job (`httpbin`, and the mitmproxy forward proxies `proxy` and `auth-proxy`), reached by service name through `HTTPBIN_URL`, `PROXY_URL` and `AUTH_PROXY_URL` (defined in `spec/support/integration_helper.rb`). Service containers can't be built from the repository, so avoid scenarios needing custom images. When adding or changing one, also update the readiness checks in the workflow and `bin/integration-tests`.
- Anything needing per-run configuration is an in-process helper in `spec/support/integration/` (e.g. `TestPKI` and `TLSServer` for TLS and mutual TLS). Start it in `before(:context)` and stop it in `after(:context)`. Do not implement servers we would have to maintain (such as a proxy) when a service container can do the job, and never commit certificates or keys.
- Assert on what the server saw (httpbin echoes requests; `TLSServer` echoes the client certificate and address), through real requests rather than Faraday internals. Examples must be independent and idempotent, and run within the 30s timeout the helper applies.
- Unit tests stay in `spec/faraday/`; integration tests complement them and must not replace them.

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