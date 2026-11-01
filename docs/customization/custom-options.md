# Custom Options Classes

Faraday's options classes (`Faraday::Options` and its subclasses) are being detached from `Struct`.
Two building blocks are available for code that defines its own options classes, such as adapters and middleware:

* `Faraday::OptionsLike` is a marker module. It is included by the legacy `Faraday::Options` and by `Faraday::BaseOptions`,
  so `Faraday::Utils.deep_merge!`, `Faraday::Utils.deep_merge` and `Faraday::Utils.deep_dup` can treat both the same way.
  Classes that include it should respond to `to_hash` and `deep_dup`.
* `Faraday::BaseOptions` is an abstract class that implements `from`, `update`, `merge`, `merge!`, `deep_dup`, `to_hash`
  and `inspect` for you, including nested coercion.

## Defining a class

A subclass lists its attributes in `MEMBERS` and defines a public reader and writer for each of them.
`COERCIONS` is optional and maps an attribute to the coercion applied to every non-`nil` value assigned to it:

* a `Class`, coerced with `Class.from(value)` (for example another `BaseOptions` subclass);
* a `Proc`, coerced with `proc.call(value)`.

```ruby
class CacheOptions < Faraday::BaseOptions
  MEMBERS = %i[ttl store].freeze

  attr_accessor :ttl, :store
end

class MyOptions < Faraday::BaseOptions
  MEMBERS = %i[timeout cache headers].freeze
  COERCIONS = { cache: CacheOptions }.freeze

  attr_accessor :timeout, :cache, :headers
end

options = MyOptions.new(timeout: 5, cache: { ttl: 60 })
options.cache.class # => CacheOptions
```

## Behavior

* `MyOptions.from(value)` returns a deep copy of `value` if it is already a `MyOptions` (the caller's object is never shared), a new empty instance for `nil`, and a new instance
  built from a `Hash`, another `OptionsLike` or anything that responds to `to_hash`. Other values raise `ArgumentError`.
* `new` accepts a single optional hash, so `MyOptions.new(timeout: 5)` works too.
* Attributes are only read and written through their public readers and writers, so a subclass can override them.
* Keys can be symbols or strings, and are normalized to symbols. A key that is not in `MEMBERS` raises `NoMethodError`,
  like it does for `Faraday::Options`.
* `nil` values are skipped by `new`, `update` and `merge!`, so they never overwrite an existing value. `false` does.
* `merge!` deep merges a hash into the existing hash or options value of the same attribute, recursively.
  Other values are replaced. Nested options objects are replaced by a merged copy rather than mutated.
* `merge` and `deep_dup` copy hashes, arrays and nested options recursively, so the result shares none of them with the
  original. Any other object (strings, procs, IO objects and so on) is kept as is.
* `to_hash` skips `nil` attributes and converts nested options to hashes. Because `deep_dup` and `merge` go through
  `to_hash`, an attribute holding an options object needs a matching entry in `COERCIONS` to stay an options object.

```ruby
options.merge(cache: { store: :memory }).to_hash
# => { timeout: 5, cache: { ttl: 60, store: :memory } }
options.merge!(timeout: nil, 'cache' => { 'ttl' => 30 })
options.to_hash # => { timeout: 5, cache: { ttl: 30 } }
```

`Faraday::Utils.deep_merge!(target, hash)` accepts a `BaseOptions` as `target` and calls `target.merge!(hash)`.
