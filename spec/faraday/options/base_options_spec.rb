# frozen_string_literal: true

RSpec.describe Faraday::BaseOptions do
  let(:nested_options_class) do
    Class.new(described_class) do
      const_set(:MEMBERS, [:value].freeze)
      attr_accessor :value
    end
  end
  let(:simple_options_class) do
    Class.new(described_class) do
      const_set(:MEMBERS, %i[timeout open_timeout].freeze)
      attr_accessor :timeout, :open_timeout
    end
  end
  let(:parent_options_class) do
    nested = nested_options_class
    Class.new(described_class) do
      const_set(:MEMBERS, %i[name count nested headers].freeze)
      const_set(:COERCIONS, { nested: nested }.freeze)
      attr_accessor :name, :count, :nested, :headers
    end
  end

  describe 'OptionsLike inclusion' do
    it 'includes OptionsLike module' do
      expect(simple_options_class.new).to be_a(Faraday::OptionsLike)
    end
  end

  describe 'defaults' do
    it 'defines empty frozen MEMBERS and COERCIONS' do
      expect(described_class::MEMBERS).to eq([]).and be_frozen
      expect(described_class::COERCIONS).to eq({}).and be_frozen
    end

    it 'lets subclasses omit COERCIONS' do
      expect(simple_options_class::COERCIONS).to eq({})
      expect(simple_options_class.new(timeout: 1).timeout).to eq(1)
    end
  end

  describe '.from' do
    it 'returns a new instance for nil' do
      result = simple_options_class.from(nil)
      expect(result).to be_a(simple_options_class)
      expect(result.timeout).to be_nil
    end

    it 'returns the same instance if already an instance' do
      original = simple_options_class.new(timeout: 10)
      expect(simple_options_class.from(original)).to equal(original)
    end

    it 'builds a new instance from a hash' do
      result = simple_options_class.from(timeout: 10, open_timeout: 5)
      expect(result).to be_a(simple_options_class)
      expect(result.timeout).to eq(10)
      expect(result.open_timeout).to eq(5)
    end

    it 'builds a new instance from another BaseOptions class' do
      other = Class.new(described_class) do
        const_set(:MEMBERS, [:timeout].freeze)
        attr_accessor :timeout
      end.new(timeout: 3)

      result = simple_options_class.from(other)
      expect(result).to be_a(simple_options_class)
      expect(result.timeout).to eq(3)
    end

    it 'builds a new instance from a legacy Options' do
      legacy = Faraday::Options.new(:timeout).new(7)

      result = simple_options_class.from(legacy)
      expect(result).to be_a(simple_options_class)
      expect(result.timeout).to eq(7)
    end

    it 'builds a new instance from an object responding to to_hash' do
      hash_like = instance_double(Hash, to_hash: { timeout: 10 })
      expect(simple_options_class.from(hash_like).timeout).to eq(10)
    end

    it 'raises ArgumentError for unsupported types' do
      expect { simple_options_class.from(42) }.to raise_error(ArgumentError, /unsupported options: Integer/)
      expect { simple_options_class.from('timeout') }.to raise_error(ArgumentError, /String/)
    end

    it 'returns the correct subclass' do
      subclass = Class.new(simple_options_class)
      expect(subclass.from(timeout: 10)).to be_a(subclass)
    end

    it 'builds a new instance from an instance of a parent class' do
      parent = simple_options_class.new(timeout: 1)
      subclass = Class.new(simple_options_class)

      result = subclass.from(parent)
      expect(result).to be_a(subclass)
      expect(result.timeout).to eq(1)
    end
  end

  describe '#initialize' do
    it 'creates an instance with nil values by default' do
      options = simple_options_class.new
      expect(options.timeout).to be_nil
      expect(options.open_timeout).to be_nil
    end

    it 'accepts keyword-style arguments' do
      options = simple_options_class.new(timeout: 10, open_timeout: 5)
      expect(options.timeout).to eq(10)
      expect(options.open_timeout).to eq(5)
    end

    it 'accepts a positional hash' do
      options = simple_options_class.new({ timeout: 10 })
      expect(options.timeout).to eq(10)
    end

    it 'accepts string keys' do
      options = simple_options_class.new('timeout' => 10, 'open_timeout' => 5)
      expect(options.timeout).to eq(10)
      expect(options.open_timeout).to eq(5)
    end

    it 'accepts an object responding to to_hash' do
      hash_like = instance_double(Hash, to_hash: { timeout: 10 })
      expect(simple_options_class.new(hash_like).timeout).to eq(10)
    end

    it 'preserves false values' do
      options = simple_options_class.new(timeout: false, 'open_timeout' => false)
      expect(options.timeout).to be(false)
      expect(options.open_timeout).to be(false)
    end

    it 'ignores nil values' do
      options = parent_options_class.new(name: nil, nested: nil)
      expect(options.name).to be_nil
      expect(options.nested).to be_nil
    end

    it 'raises NoMethodError for unknown keys, like legacy Options' do
      expect { simple_options_class.new(timeout: 10, unknown: 'value') }.to raise_error(NoMethodError, /unknown/)
      expect { Faraday::Options.new(:timeout).from(timeout: 10, unknown: 1) }.to raise_error(NoMethodError)
    end

    it 'does not call writers that are not members' do
      klass = Class.new(simple_options_class) do
        attr_writer :extra
      end

      expect { klass.new(extra: 1) }.to raise_error(NoMethodError, /extra/)
    end

    it 'uses the public writers' do
      klass = Class.new(simple_options_class) do
        def timeout=(value)
          @timeout = value * 2
        end
      end

      expect(klass.new(timeout: 5).timeout).to eq(10)
    end
  end

  describe '#update' do
    it 'updates existing instance with new values' do
      options = simple_options_class.new(timeout: 10)
      result = options.update(timeout: 20, open_timeout: 5)
      expect(result).to equal(options)
      expect(options.timeout).to eq(20)
      expect(options.open_timeout).to eq(5)
    end

    it 'accepts an object responding to to_hash' do
      options = simple_options_class.new(timeout: 10)
      options.update(instance_double(Hash, to_hash: { timeout: 20 }))
      expect(options.timeout).to eq(20)
    end

    it 'accepts a legacy Options' do
      options = simple_options_class.new(timeout: 10, open_timeout: 1)
      options.update(Faraday::Options.new(:timeout).new(20))
      expect(options.timeout).to eq(20)
      expect(options.open_timeout).to eq(1)
    end

    it 'does not overwrite values with nil' do
      options = simple_options_class.new(timeout: 10)
      options.update(timeout: nil, 'open_timeout' => nil)
      expect(options.timeout).to eq(10)
      expect(options.open_timeout).to be_nil
    end

    it 'overwrites values with false' do
      options = simple_options_class.new(timeout: 10)
      options.update(timeout: false)
      expect(options.timeout).to be(false)
    end

    it 'updates the member for string keys without creating another key' do
      options = simple_options_class.new(timeout: 10)
      options.update('timeout' => 20)
      expect(options.timeout).to eq(20)
      expect(options.to_hash).to eq(timeout: 20)
    end

    it 'raises NoMethodError for unknown keys' do
      options = simple_options_class.new(timeout: 10)
      expect { options.update(timeout: 20, unknown: 'value') }.to raise_error(NoMethodError, /unknown/)
    end

    it 'uses the public writers' do
      klass = Class.new(simple_options_class) do
        def timeout=(value)
          @timeout = value * 2
        end
      end

      expect(klass.new.update(timeout: 5).timeout).to eq(10)
    end

    it 'coerces nested values' do
      options = parent_options_class.new
      options.update(nested: { value: 'updated' })
      expect(options.nested).to be_a(nested_options_class)
      expect(options.nested.value).to eq('updated')
    end
  end

  describe '#merge!' do
    it 'updates instance in place and returns self' do
      options = simple_options_class.new(timeout: 10)
      result = options.merge!(timeout: 20, open_timeout: 5)
      expect(result).to equal(options)
      expect(options.timeout).to eq(20)
      expect(options.open_timeout).to eq(5)
    end

    it 'accepts an object responding to to_hash' do
      options = simple_options_class.new(timeout: 10)
      options.merge!(instance_double(Hash, to_hash: { timeout: 20 }))
      expect(options.timeout).to eq(20)
    end

    it 'does not overwrite values with nil' do
      options = parent_options_class.new(name: 'a', nested: { value: 1 })
      options.merge!(name: nil, nested: nil)
      expect(options.name).to eq('a')
      expect(options.nested.value).to eq(1)
    end

    it 'overwrites values with false' do
      options = simple_options_class.new(timeout: 10)
      options.merge!(timeout: false)
      expect(options.timeout).to be(false)
    end

    it 'deep merges a hash into nested options' do
      options = parent_options_class.new(name: 'test', nested: { value: 'a' })
      options.merge!(nested: { value: 'b' })

      expect(options.name).to eq('test')
      expect(options.nested).to be_a(nested_options_class)
      expect(options.nested.value).to eq('b')
    end

    it 'deep merges nested options instances' do
      klass = Class.new(described_class) do
        const_set(:MEMBERS, %i[a b].freeze)
        attr_accessor :a, :b
      end
      parent_class = Class.new(described_class) do
        const_set(:MEMBERS, [:child].freeze)
        const_set(:COERCIONS, { child: klass }.freeze)
        attr_accessor :child
      end
      options = parent_class.new(child: { a: 1 })
      options.merge!(child: klass.new(b: 2))

      expect(options.child.to_hash).to eq(a: 1, b: 2)
    end

    it 'keeps nested values that are not part of the merged hash' do
      klass = Class.new(described_class) do
        const_set(:MEMBERS, %i[a b].freeze)
        attr_accessor :a, :b
      end
      parent_class = Class.new(described_class) do
        const_set(:MEMBERS, [:child].freeze)
        const_set(:COERCIONS, { child: klass }.freeze)
        attr_accessor :child
      end
      options = parent_class.new(child: { a: 1, b: 2 })
      options.merge!(child: { b: nil })

      expect(options.child.to_hash).to eq(a: 1, b: 2)
    end

    it 'deep merges nested options with string keys' do
      options = parent_options_class.new(nested: { value: 'a' })
      options.merge!('nested' => { 'value' => 'b' })

      expect(options.nested.value).to eq('b')
      expect(options.to_hash).to eq(nested: { value: 'b' })
    end

    it 'does not shadow symbol keys with string keys' do
      options = simple_options_class.new(timeout: 10)
      options.merge!('timeout' => 20)

      expect(options.timeout).to eq(20)
      expect(options.to_hash).to eq(timeout: 20)
    end

    it 'deep merges hash members' do
      options = parent_options_class.new(headers: { a: 1, b: { c: 2 } })
      options.merge!(headers: { b: { d: 3 } })

      expect(options.headers).to eq(a: 1, b: { c: 2, d: 3 })
    end

    it 'replaces hash members that are not mergeable' do
      options = parent_options_class.new(headers: { a: 1 })
      options.merge!(headers: 'none')

      expect(options.headers).to eq('none')
    end

    it 'does not mutate the nested options instance in place' do
      nested = nested_options_class.new(value: 'a')
      options = parent_options_class.new(nested: nested)
      options.merge!(nested: { value: 'b' })

      expect(nested.value).to eq('a')
      expect(options.nested.value).to eq('b')
    end

    it 'raises NoMethodError for unknown keys' do
      options = simple_options_class.new
      expect { options.merge!(unknown: 1) }.to raise_error(NoMethodError, /unknown/)
    end

    it 'uses the public readers and writers' do
      klass = Class.new(simple_options_class) do
        def timeout
          super || 99
        end

        def timeout=(value)
          @timeout = value * 2
        end
      end
      options = klass.new
      options.merge!(timeout: 5)

      expect(options.timeout).to eq(10)
    end
  end

  describe '#merge' do
    it 'returns a new instance with merged values' do
      options = simple_options_class.new(timeout: 10)
      result = options.merge(timeout: 20, open_timeout: 5)
      expect(result).to be_a(simple_options_class)
      expect(result).not_to equal(options)
      expect(result.timeout).to eq(20)
      expect(result.open_timeout).to eq(5)
      expect(options.timeout).to eq(10)
      expect(options.open_timeout).to be_nil
    end

    it 'deeply merges nested options without altering the receiver' do
      options = parent_options_class.new(name: 'test', nested: { value: 'a' })
      result = options.merge(nested: { value: 'b' })

      expect(result.name).to eq('test')
      expect(result.nested).to be_a(nested_options_class)
      expect(result.nested.value).to eq('b')
      expect(options.nested.value).to eq('a')
    end

    it 'does not share nested objects with the receiver' do
      options = parent_options_class.new(nested: { value: 'a' }, headers: { a: { b: 1 } }, count: 1)
      result = options.merge(count: 2)

      expect(result.nested).not_to equal(options.nested)
      expect(result.headers).not_to equal(options.headers)

      result.nested.value = 'changed'
      result.headers[:a][:b] = 2
      expect(options.nested.value).to eq('a')
      expect(options.headers).to eq(a: { b: 1 })
    end
  end

  describe '#deep_dup' do
    it 'creates a copy of the instance' do
      options = simple_options_class.new(timeout: 10, open_timeout: 5)
      duped = options.deep_dup

      expect(duped).to be_a(simple_options_class)
      expect(duped).not_to equal(options)
      expect(duped.timeout).to eq(10)
      expect(duped.open_timeout).to eq(5)

      duped.timeout = 20
      expect(options.timeout).to eq(10)
    end

    it 'preserves false values' do
      expect(simple_options_class.new(timeout: false).deep_dup.timeout).to be(false)
    end

    it 'deeply duplicates nested options' do
      nested = nested_options_class.new(value: 'original')
      options = parent_options_class.new(name: 'test', nested: nested)
      duped = options.deep_dup

      expect(duped.nested).to be_a(nested_options_class)
      expect(duped.nested).not_to equal(nested)
      expect(duped.nested.value).to eq('original')

      duped.nested.value = 'modified'
      expect(options.nested.value).to eq('original')
    end

    it 'deeply duplicates hash values' do
      options = parent_options_class.new(headers: { nested: { value: 1 } })
      duped = options.deep_dup

      expect(duped.headers).not_to equal(options.headers)
      duped.headers[:nested][:value] = 2
      expect(options.headers[:nested][:value]).to eq(1)
    end

    it 'deeply duplicates array values' do
      options = simple_options_class.new(timeout: [1, 2, { key: 'value' }])
      duped = options.deep_dup

      expect(duped.timeout).not_to equal(options.timeout)
      duped.timeout[2][:key] = 'modified'
      expect(options.timeout[2][:key]).to eq('value')
    end

    it 'uses the public readers' do
      klass = Class.new(simple_options_class) do
        def timeout
          super || 99
        end
      end

      expect(klass.new.deep_dup.timeout).to eq(99)
    end
  end

  describe '#to_hash' do
    it 'converts the instance to a hash with symbol keys' do
      options = simple_options_class.new(timeout: 10, open_timeout: 5)
      expect(options.to_hash).to eq(timeout: 10, open_timeout: 5)
    end

    it 'skips nil values and keeps false' do
      options = simple_options_class.new(timeout: false)
      expect(options.to_hash).to eq(timeout: false)
    end

    it 'converts nested options to hashes' do
      options = parent_options_class.new(name: 'test', nested: { value: 1 })
      expect(options.to_hash).to eq(name: 'test', nested: { value: 1 })
    end

    it 'uses the public readers' do
      klass = Class.new(simple_options_class) do
        def timeout
          super || 99
        end
      end

      expect(klass.new.to_hash).to eq(timeout: 99)
    end
  end

  describe '#inspect' do
    it 'lists the members that are set' do
      stub_const('SimpleOptions', simple_options_class)
      options = simple_options_class.new(timeout: 10, open_timeout: false)

      expect(options.inspect).to eq('#<SimpleOptions timeout=10, open_timeout=false>')
    end

    it 'skips nil values' do
      stub_const('SimpleOptions', simple_options_class)

      expect(simple_options_class.new(timeout: 10).inspect).to eq('#<SimpleOptions timeout=10>')
    end

    it 'shows empty instances' do
      stub_const('SimpleOptions', simple_options_class)

      expect(simple_options_class.new.inspect).to eq('#<SimpleOptions (empty)>')
    end
  end

  describe 'coercion' do
    it 'coerces nested values based on COERCIONS' do
      options = parent_options_class.new(nested: { value: 'test' })
      expect(options.nested).to be_a(nested_options_class)
      expect(options.nested.value).to eq('test')
    end

    it 'does not coerce a value that is already of the correct type' do
      nested = nested_options_class.new(value: 'test')
      expect(parent_options_class.new(nested: nested).nested).to equal(nested)
    end

    it 'calls from on Class coercions' do
      coercion = Class.new do
        def self.from(value)
          "from:#{value}"
        end
      end
      klass = Class.new(described_class) do
        const_set(:MEMBERS, [:a].freeze)
        const_set(:COERCIONS, { a: coercion }.freeze)
        attr_accessor :a
      end

      expect(klass.new(a: 1).a).to eq('from:1')
    end

    it 'calls Proc coercions' do
      klass = Class.new(described_class) do
        const_set(:MEMBERS, [:a].freeze)
        const_set(:COERCIONS, { a: ->(value) { "proc:#{value}" } }.freeze)
        attr_accessor :a
      end

      expect(klass.new(a: 1).a).to eq('proc:1')
      expect(klass.new.update(a: 2).a).to eq('proc:2')
      expect(klass.new.merge!(a: 3).a).to eq('proc:3')
    end

    it 'does not coerce nil' do
      klass = Class.new(described_class) do
        const_set(:MEMBERS, [:a].freeze)
        const_set(:COERCIONS, { a: ->(value) { "coerced:#{value}" } }.freeze)
        attr_accessor :a
      end

      expect(klass.new(a: nil).a).to be_nil
    end
  end
end
