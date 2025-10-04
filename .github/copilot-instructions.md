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

1. **Read & Follow**: Always reference `.ai/guidelines.md` for all Faraday conventions and implementation details
2. **Stay Current**: Suggest updates to `.ai/guidelines.md` when you notice:
   - New patterns not yet documented
   - Changes to existing conventions
   - Discrepancies between guidelines and actual code
3. **Focus on Faraday**: Provide Faraday-specific guidance, not generic Ruby/RSpec tips

## Critical Context

### Middleware and Adapters
- **New middleware and adapters should be separate gems**, NOT added to the base Faraday repository
- Only middleware expected to be used by the vast majority of projects can be considered for the base repo
- See [faraday-net_http](https://github.com/lostisland/faraday-net_http) as an example of an adapter in its own repository
- Consult `.ai/guidelines.md` for detailed implementation patterns

### Code Quality
- Follow RuboCop style guide (`.rubocop.yml`)
- Run tests: `bundle exec rspec`
- Check style: `bundle exec rubocop`
- Use inclusive language (see `.github/CONTRIBUTING.md`)

## Self-Maintaining Guidelines
Keep `.ai/guidelines.md` accurate and current. When you identify code patterns not reflected in guidelines, convention changes, or better practices, propose updates to maintain alignment with the actual codebase.

## Reference Files
- **`.ai/guidelines.md`** - Complete conventions and patterns (PRIMARY REFERENCE)
- `.github/CONTRIBUTING.md` - Contribution process and workflow
- `lib/faraday/middleware.rb` - Middleware base class
- `lib/faraday/request/json.rb` - Example middleware implementation
- `.rubocop.yml` - Code style guide

---

**Remember**: The guidelines in `.ai/guidelines.md` are the source of truth for Faraday conventions. Keep them current and refer to them consistently.
