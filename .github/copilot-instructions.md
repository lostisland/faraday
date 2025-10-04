# GitHub Copilot Instructions for Faraday

## Essential Reading
**Before making any code suggestions**, consult `.ai/guidelines.md` for comprehensive Faraday-specific conventions and patterns.

## About This Repository
Faraday is a Ruby HTTP client library that provides:
- A middleware-based architecture (similar to Rack)
- A common interface over various HTTP adapters (Net::HTTP, HTTPClient, etc.)
- Extensible request/response processing pipeline

## Your Responsibilities
As GitHub Copilot working on Faraday, you must:

1. **Read & Follow**: Always reference `.ai/guidelines.md` for Faraday conventions
2. **Stay Current**: Suggest updates to `.ai/guidelines.md` when you notice:
   - New patterns not yet documented
   - Changes to existing conventions
   - Discrepancies between guidelines and actual code
3. **Focus on Faraday**: Provide Faraday-specific guidance, not generic Ruby/RSpec tips

## Core Architecture Patterns

### Middleware System
All middleware must:
- Inherit from `Faraday::Middleware`
- Define `DEFAULT_OPTIONS` constant if configurable
- Implement only required hooks: `on_request`, `on_complete`, or `on_error`
- Register with a unique key via `Faraday::Middleware.register_middleware`
- Remain stateless (store state in `env` hash only)

Example structure:
```ruby
module Faraday
  class Request
    class MyMiddleware < Middleware
      DEFAULT_OPTIONS = { option: 'value' }.freeze

      def on_request(env)
        # Modify request
      end
    end
  end
end

Faraday::Request.register_middleware(my_middleware: Faraday::Request::MyMiddleware)
```

### Adapter System
All adapters must:
- Extend `Faraday::MiddlewareRegistry`
- Implement `call(env)` method
- Implement `build_connection(env)` for connection setup
- Implement `close` for cleanup
- Be placed in `lib/faraday/adapter/`
- Register via `Faraday::Adapter.register_middleware`

For parallel support:
- Include `Parallelism` module
- Set `supports_parallel = true`

### Testing Conventions
- Use RSpec for all tests
- Leverage shared examples for adapters and middleware (see `spec/support`)
- Mock HTTP calls; never make real network requests
- Follow test organization: `spec/faraday/` mirrors `lib/faraday/`
- Test middleware: use doubles for `app` and verify hook invocations

### Documentation Standards
- Add YARD comments to all public APIs
- Update `docs/` for user-facing features
- Keep README.md and CHANGELOG.md current
- Document new middleware/adapters in `docs/` folder

## Project Structure
```
lib/faraday/
├── adapter/              # HTTP backend adapters
│   └── test.rb          # Test adapter (example)
├── request/             # Request middleware
│   ├── json.rb         # JSON encoding (example)
│   └── authorization.rb
├── response/            # Response middleware
├── middleware.rb        # Base middleware class
└── adapter.rb          # Base adapter class

spec/faraday/
└── (mirrors lib structure)
```

## Code Quality Requirements
- Follow RuboCop style guide (`.rubocop.yml`)
- Ensure all code passes: `bundle exec rubocop`
- All features need tests: `bundle exec rspec`
- Use inclusive language (see `.github/CONTRIBUTING.md`)

## Contribution Process
1. Check `.github/CONTRIBUTING.md` for workflow
2. New features require tests and documentation
3. Adapters/middleware should be separate gems (link from this project)
4. Follow semantic versioning for breaking changes

## Self-Maintaining Guidelines
You are responsible for keeping `.ai/guidelines.md` accurate and current. When you identify:
- Code patterns not reflected in guidelines
- Convention changes
- Better practices

Propose updates to `.ai/guidelines.md` to maintain alignment with the actual codebase.

## Reference Files
- **Complete Guidelines**: `.ai/guidelines.md` (PRIMARY REFERENCE)
- **Contribution Guide**: `.github/CONTRIBUTING.md`
- **Middleware Base**: `lib/faraday/middleware.rb`
- **Middleware Example**: `lib/faraday/request/json.rb`
- **Adapter Example**: `lib/faraday/adapter/test.rb`
- **Style Guide**: `.rubocop.yml`

---

**Remember**: The guidelines in `.ai/guidelines.md` are the source of truth for Faraday conventions. Keep them current and refer to them consistently.
