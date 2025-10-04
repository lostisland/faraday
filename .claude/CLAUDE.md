# Claude AI Agent Instructions for Faraday

## About Faraday
Faraday is a Ruby HTTP client library with a middleware-based architecture (similar to Rack). It provides a common interface over various HTTP adapters and uses middleware for request/response processing.

## Primary Directive
**Before making any code changes or suggestions**, you **must** read and follow the comprehensive guidelines in `.ai/guidelines.md`.

## Your Responsibilities
1. **Read** `.ai/guidelines.md` for all Faraday-specific conventions and patterns
2. **Follow** the established conventions documented there
3. **Propose updates** to `.ai/guidelines.md` when you identify:
   - New code patterns not yet documented
   - Changes to existing conventions
   - Inconsistencies between guidelines and actual codebase

## Important Context
- **New middleware and adapters** should be created as separate gems, NOT added to the base Faraday repository (with rare exceptions for widely-used core middleware)
- See [faraday-net_http](https://github.com/lostisland/faraday-net_http) as an example adapter in its own repository
- Focus on Faraday-specific patterns, not generic Ruby/RSpec advice

## Reference Files
- **`.ai/guidelines.md`** - Complete Faraday conventions (PRIMARY REFERENCE)
- `.github/CONTRIBUTING.md` - Contribution process and policies
- `lib/faraday/middleware.rb` - Middleware base class
- `lib/faraday/request/json.rb` - Example middleware implementation

---

**Keep `.ai/guidelines.md` current.** Propose updates when you notice any drift between documentation and reality.
