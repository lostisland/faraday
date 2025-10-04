# Claude AI Agent Instructions for Faraday

## Overview
You are working on the **Faraday** repository, a Ruby HTTP client library with a middleware-based architecture. Before making any code changes or suggestions, you **must** read and follow the comprehensive guidelines in `.ai/guidelines.md`.

## Primary Directive
**Always reference `.ai/guidelines.md`** for:
- Code style and structure conventions
- Middleware implementation patterns
- Adapter development guidelines
- Testing requirements with RSpec
- Documentation standards (YARD)
- Contribution workflow

## Self-Maintaining Responsibility
As a Claude AI agent, you are responsible for:
1. **Reading** `.ai/guidelines.md` before every contribution
2. **Following** all Faraday-specific conventions outlined there
3. **Proposing updates** to `.ai/guidelines.md` when you identify:
   - New code patterns not yet documented
   - Changes to existing conventions
   - Improved practices that should become standard
   - Inconsistencies between the guidelines and actual codebase

## Key Faraday Concepts
- **Middleware Architecture**: All middleware inherit from `Faraday::Middleware` and use hooks (`on_request`, `on_complete`, `on_error`)
- **Adapter Pattern**: Adapters extend `Faraday::MiddlewareRegistry` and implement `call`, `build_connection`, etc.
- **Registry System**: Both middleware and adapters register themselves with unique keys
- **Testing**: Use RSpec with shared examples, stubs instead of real network calls
- **Documentation**: YARD comments for all public APIs

## What NOT to Do
- Do not provide generic Ruby or RSpec advice—focus on Faraday-specific patterns
- Do not suggest changes that violate established conventions without first proposing guideline updates
- Do not implement middleware or adapters without checking existing patterns in the codebase

## Quick Reference
- Main guidelines: `.ai/guidelines.md`
- Contributing guide: `.github/CONTRIBUTING.md`
- Example middleware: `lib/faraday/request/json.rb`
- Example adapter: `lib/faraday/adapter/test.rb`
- Middleware base: `lib/faraday/middleware.rb`

---

**Remember**: Keep `.ai/guidelines.md` current. If you notice any drift between documentation and reality, propose updates to maintain accuracy.
