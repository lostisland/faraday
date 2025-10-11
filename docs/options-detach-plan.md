# RFC/Tracking: Detach Options subclasses into explicit OOP (BaseOptions + OptionsLike), keep legacy Options

## Summary
- Keep Faraday::Options as-is for backward compatibility.
- Detach existing subclasses (ConnectionOptions, RequestOptions, SSLOptions, ProxyOptions, Env) into explicit OOP classes that do not inherit from Options.
- Introduce:
  - Faraday::OptionsLike (marker module) to identify "options-like" objects.
  - Faraday::BaseOptions (abstract superclass) that centralizes .from/update/merge!/merge/deep_dup/to_hash/inspect and nested coercion via constants.
- Drop legacy ergonomics for detached subclasses (Struct indexing, fetch, each_key, .options macro, .memoized macro). Preserve Env's hash-like []/[]= since middleware uses it.
- Convert classes one-by-one: ProxyOptions → RequestOptions → SSLOptions → ConnectionOptions → Env.

## Main decisions
- Inheritance + marker: BaseOptions reduces duplication and drift for correctness-sensitive logic (nested coercion/merge/deep-dup). OptionsLike provides a stable way to integrate with Utils.deep_merge! and any duck-typed interop.
- Back-compat boundary: Faraday::Options remains unchanged. New classes' .from accept Hash and legacy Options (via to_hash). Deep-merge continues to work on both legacy and new options classes.
- Ergonomics: For internal code we drop Struct-like features. Env keeps []/[]=.

## Short code examples

### OptionsLike and BaseOptions

```ruby
module Faraday
  module OptionsLike; end

  class BaseOptions
    include OptionsLike

    MEMBERS = [].freeze        # override in subclasses
    COERCIONS = {}.freeze      # key => Class or Proc

    def self.from(value)
      case value
      when nil
        new
      when self
        value
      when OptionsLike
        new.update(value.to_hash)
      when Hash
        new.update(value)
      else
        raise ArgumentError, "unsupported options: #{value.class}"
      end
    end

    def initialize(**attrs)
      attrs.each { |k, v| public_send("#{k}=", coerce(k, v)) }
    end

    def update(hash_like)
      hash_like.each { |k, v| public_send("#{k}=", coerce(k, v)) }
      self
    end

    def merge!(other)
      other.each do |k, v|
        next if v.nil?
        cur = public_send(k)
        newv = coerce(k, v)
        if cur.is_a?(OptionsLike) && newv.is_a?(OptionsLike)
          cur.merge!(newv.to_hash)
        else
          public_send("#{k}=", newv)
        end
      end
      self
    end

    def merge(other)
      self.class.from(to_hash).merge!(other)
    end

    def deep_dup
      self.class.from(to_hash)
    end

    def to_hash
      self.class::MEMBERS.each_with_object({}) do |k, h|
        v = public_send(k)
        next if v.nil?
        h[k] = v.is_a?(OptionsLike) ? v.to_hash : v
      end
    end

    def inspect
      pairs = to_hash.map { |k, v| "#{k}=#{v.inspect}" }
      "#<#{self.class} #{pairs.join(', ')}>"
    end

    private

    def coerce(key, value)
      return value if value.nil?
      coercer = self.class::COERCIONS[key.to_sym]
      case coercer
      when Class then coercer.from(value)
      when Proc  then coercer.call(value)
      else            value
      end
    end
  end
end
```

### ProxyOptions (detached)

```ruby
class Faraday::ProxyOptions < Faraday::BaseOptions
  MEMBERS = [:uri, :user, :password].freeze
  attr_accessor(*MEMBERS)

  COERCIONS = {
    uri: ->(v) do
      case v
      when String
        v = "http://#{v}" unless v.include?('://')
        Faraday::Utils.URI(v)
      when URI
        v
      else
        v
      end
    end
  }.freeze

  def user
    @user || (uri && Faraday::Utils.unescape(uri.user))
  end

  def password
    @password || (uri && Faraday::Utils.unescape(uri.password))
  end
end
```

### Utils.deep_merge! change

```ruby
# lib/faraday/utils.rb
# Treat OptionsLike like Options when deep-merging nested structures
if value.is_a?(Hash) && (target_value.is_a?(Hash) || target_value.is_a?(Faraday::OptionsLike))
  target[key] = deep_merge(target_value, value)
else
  target[key] = value
end
```

## Incremental rollout
1) Foundation: add OptionsLike + BaseOptions; update Utils.deep_merge!.
2) Convert ProxyOptions (smallest surface, minimal coupling).
3) Convert RequestOptions (ensure proxy coercion and deep_merge! semantics).
4) Convert SSLOptions (larger surface; explicit lazy cert_store).
5) Convert ConnectionOptions (nested request/ssl, builder_class default, new_builder).
6) Convert Env last (preserve []/[]= and to_hash; confirm middleware compatibility).
7) Tests/docs: expand tests for nested coercion, nil-preserving merge, deep_dup, to_hash; update docs.

## Tasks (use "Create issue from task list")
- [ ] Foundation: Introduce OptionsLike and BaseOptions; update Utils.deep_merge!
  - Files: add lib/faraday/options_like.rb, lib/faraday/base_options.rb; modify lib/faraday/utils.rb
  - Tests: BaseOptions unit tests; deep_merge! tests for OptionsLike
  - Docs: brief section on OptionsLike/BaseOptions
  - Research: grep for is_a?(Options) checks and update where needed
- [ ] Convert ProxyOptions to BaseOptions (preserve behavior; drop Struct ergonomics)
  - Files: lib/faraday/options/proxy_options.rb
  - Tests: string/URI coercion, empty string => nil (via RequestOptions#proxy=), user/password derivation
  - Research: find ProxyOptions usages and delegators (scheme/host/port/path)
- [ ] Convert RequestOptions to BaseOptions (keep proxy coercion and stream_response?)
  - Files: lib/faraday/options/request_options.rb
  - Tests: nested proxy coercion, deep_merge!, to_hash
  - Research: usages of []/[]= on RequestOptions; replace with explicit accessors
- [ ] Convert SSLOptions to BaseOptions (preserve lazy cert_store and semantics)
  - Files: lib/faraday/options/ssl_options.rb
  - Tests: coercion, deep_dup, to_hash, lazy cert_store
  - Research: adapter interactions with SSLOptions
- [ ] Convert ConnectionOptions to BaseOptions (coerce request/ssl; default builder_class)
  - Files: lib/faraday/options/connection_options.rb, lib/faraday.rb
  - Tests: Faraday.new/default_connection_options, deep_merge!, builder behavior
  - Research: usages of members/values/[]; migrate to explicit access
- [ ] Convert Env (last; preserve middleware hash-like API)
  - Files: lib/faraday/options/env.rb
  - Tests: env and middleware integration
  - Research: env[:key] usages; avoid breaking third-party middleware
- [ ] Optional: Deprecate Options.memoized macro (new classes don't use it)
  - Files: lib/faraday/options.rb
  - Tests/Docs: deprecation notice and changelog entry
