# frozen_string_literal: true

RSpec.describe Faraday::BaseOptions do
  # Test subclasses to validate BaseOptions behavior
  # Using Test prefix to avoid conflicts with existing classes
  module TestClasses
    class SimpleOptions < Faraday::BaseOptions
      MEMBERS = %i[timeout open_timeout].freeze
      COERCIONS = {}.freeze

      attr_accessor :timeout, :open_timeout
    end

    class NestedOptions < Faraday::BaseOptions
      MEMBERS = [:value].freeze
      COERCIONS = {}.freeze

      attr_accessor :value
    end

    class ParentOptions < Faraday::BaseOptions
      MEMBERS = %i[name count nested].freeze
      COERCIONS = { nested: NestedOptions }.freeze

      attr_accessor :name, :count, :nested
    end
  end

  let(:simple_options_class) { TestClasses::SimpleOptions }
  let(:nested_options_class) { TestClasses::NestedOptions }
  let(:parent_options_class) { TestClasses::ParentOptions }

  describe 'OptionsLike inclusion' do
    it 'includes OptionsLike module' do
      expect(simple_options_class.new).to be_a(Faraday::OptionsLike)
    end
  end

  describe '.from' do
    context 'with nil' do
      it 'returns new instance' do
        result = simple_options_class.from(nil)
        expect(result).to be_a(simple_options_class)
        expect(result.timeout).to be_nil
      end
    end

    context 'with instance of same class' do
      it 'returns the same instance' do
        original = simple_options_class.new(timeout: 10)
        result = simple_options_class.from(original)
        expect(result).to equal(original)
      end
    end

    context 'with hash' do
      it 'creates new instance from hash' do
        result = simple_options_class.from(timeout: 10, open_timeout: 5)
        expect(result).to be_a(simple_options_class)
        expect(result.timeout).to eq(10)
        expect(result.open_timeout).to eq(5)
      end
    end

    context 'with object responding to to_hash' do
      it 'creates new instance from to_hash result' do
        hash_like = double('hash_like', to_hash: { timeout: 10 })
        result = simple_options_class.from(hash_like)
        expect(result).to be_a(simple_options_class)
        expect(result.timeout).to eq(10)
      end
    end
  end

  describe '#initialize' do
    context 'with empty hash' do
      it 'creates instance with nil values' do
        options = simple_options_class.new
        expect(options.timeout).to be_nil
        expect(options.open_timeout).to be_nil
      end
    end

    context 'with symbol keys' do
      it 'sets values from hash' do
        options = simple_options_class.new(timeout: 10, open_timeout: 5)
        expect(options.timeout).to eq(10)
        expect(options.open_timeout).to eq(5)
      end
    end

    context 'with string keys' do
      it 'sets values from hash with string keys' do
        options = simple_options_class.new('timeout' => 10, 'open_timeout' => 5)
        expect(options.timeout).to eq(10)
        expect(options.open_timeout).to eq(5)
      end
    end

    context 'with object responding to to_hash' do
      it 'converts to hash before processing' do
        hash_like = double('hash_like', to_hash: { timeout: 10 })
        options = simple_options_class.new(hash_like)
        expect(options.timeout).to eq(10)
      end
    end

    context 'with unknown keys' do
      it 'ignores unknown keys' do
        options = simple_options_class.new(timeout: 10, unknown: 'value')
        expect(options.timeout).to eq(10)
        expect(options).not_to respond_to(:unknown)
      end
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

    it 'accepts object responding to to_hash' do
      options = simple_options_class.new(timeout: 10)
      hash_like = double('hash_like', to_hash: { timeout: 20 })
      options.update(hash_like)
      expect(options.timeout).to eq(20)
    end

    it 'ignores unknown keys' do
      options = simple_options_class.new(timeout: 10)
      options.update(timeout: 20, unknown: 'value')
      expect(options.timeout).to eq(20)
    end

    it 'returns self' do
      options = simple_options_class.new
      result = options.update(timeout: 10)
      expect(result).to equal(options)
    end
  end

  describe '#merge' do
    it 'returns new instance with merged values' do
      options = simple_options_class.new(timeout: 10)
      result = options.merge(timeout: 20, open_timeout: 5)
      expect(result).to be_a(simple_options_class)
      expect(result).not_to equal(options)
      expect(result.timeout).to eq(20)
      expect(result.open_timeout).to eq(5)
      expect(options.timeout).to eq(10)
      expect(options.open_timeout).to be_nil
    end

    it 'deeply merges nested options' do
      nested1 = nested_options_class.new(value: 'a')
      nested2_hash = { value: 'b' }
      options1 = parent_options_class.new(name: 'test', nested: nested1)
      result = options1.merge(nested: nested2_hash)

      expect(result.name).to eq('test')
      expect(result.nested).to be_a(nested_options_class)
      expect(result.nested.value).to eq('b')
      expect(options1.nested.value).to eq('a')
    end
  end

  describe '#merge!' do
    it 'updates instance in place with merged values' do
      options = simple_options_class.new(timeout: 10)
      result = options.merge!(timeout: 20, open_timeout: 5)
      expect(result).to equal(options)
      expect(options.timeout).to eq(20)
      expect(options.open_timeout).to eq(5)
    end

    it 'uses Utils.deep_merge! for nested structures' do
      nested = nested_options_class.new(value: 'a')
      options = parent_options_class.new(name: 'test', nested: nested)
      # rubocop:disable Performance/RedundantMerge
      options.merge!(nested: { value: 'b' })
      # rubocop:enable Performance/RedundantMerge

      expect(options.nested).to be_a(nested_options_class)
      expect(options.nested.value).to eq('b')
    end

    it 'accepts object responding to to_hash' do
      options = simple_options_class.new(timeout: 10)
      hash_like = double('hash_like', to_hash: { timeout: 20 })
      options.merge!(hash_like)
      expect(options.timeout).to eq(20)
    end
  end

  describe '#deep_dup' do
    it 'creates deep copy of instance' do
      options = simple_options_class.new(timeout: 10, open_timeout: 5)
      duped = options.deep_dup

      expect(duped).to be_a(simple_options_class)
      expect(duped).not_to equal(options)
      expect(duped.timeout).to eq(10)
      expect(duped.open_timeout).to eq(5)

      duped.timeout = 20
      expect(options.timeout).to eq(10)
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
      options = parent_options_class.new(name: 'test')
      # Manually set a hash that needs deep duplication
      options.instance_variable_set(:@count, { nested: { value: 1 } })

      duped = options.deep_dup
      duped_count = duped.instance_variable_get(:@count)
      original_count = options.instance_variable_get(:@count)

      expect(duped_count).not_to equal(original_count)
      duped_count[:nested][:value] = 2
      expect(original_count[:nested][:value]).to eq(1)
    end

    it 'deeply duplicates array values' do
      options = simple_options_class.new
      options.instance_variable_set(:@timeout, [1, 2, { key: 'value' }])

      duped = options.deep_dup
      duped_timeout = duped.instance_variable_get(:@timeout)
      original_timeout = options.instance_variable_get(:@timeout)

      expect(duped_timeout).not_to equal(original_timeout)
      duped_timeout[2][:key] = 'modified'
      expect(original_timeout[2][:key]).to eq('value')
    end
  end

  describe '#to_hash' do
    it 'converts instance to hash' do
      options = simple_options_class.new(timeout: 10, open_timeout: 5)
      hash = options.to_hash

      expect(hash).to be_a(Hash)
      expect(hash[:timeout]).to eq(10)
      expect(hash[:open_timeout]).to eq(5)
    end

    it 'includes nil values' do
      options = simple_options_class.new(timeout: 10)
      hash = options.to_hash

      expect(hash).to have_key(:timeout)
      expect(hash).to have_key(:open_timeout)
      expect(hash[:open_timeout]).to be_nil
    end

    it 'returns hash with symbol keys' do
      options = simple_options_class.new(timeout: 10)
      hash = options.to_hash

      expect(hash.keys).to all(be_a(Symbol))
    end
  end

  describe '#inspect' do
    it 'returns human-readable representation' do
      options = simple_options_class.new(timeout: 10, open_timeout: 5)
      result = options.inspect

      expect(result).to match(/^#<.*SimpleOptions/)
      expect(result).to include('timeout')
      expect(result).to include('10')
    end

    it 'includes nil values in representation' do
      options = simple_options_class.new(timeout: 10)
      result = options.inspect

      expect(result).to include('timeout')
      expect(result).to include('open_timeout')
    end
  end

  describe 'nested coercion' do
    it 'coerces nested values based on COERCIONS' do
      options = parent_options_class.new(nested: { value: 'test' })
      expect(options.nested).to be_a(nested_options_class)
      expect(options.nested.value).to eq('test')
    end

    it 'does not coerce if value is already correct type' do
      nested = nested_options_class.new(value: 'test')
      options = parent_options_class.new(nested: nested)
      expect(options.nested).to equal(nested)
    end

    it 'handles nil nested values' do
      options = parent_options_class.new(nested: nil)
      expect(options.nested).to be_nil
    end

    it 'coerces in update' do
      options = parent_options_class.new
      options.update(nested: { value: 'updated' })
      expect(options.nested).to be_a(nested_options_class)
      expect(options.nested.value).to eq('updated')
    end
  end

  describe 'inheritance' do
    it 'works with subclasses' do
      subclass = Class.new(simple_options_class)
      options = subclass.new(timeout: 10)
      expect(options).to be_a(subclass)
      expect(options.timeout).to eq(10)
    end

    it 'from returns correct subclass' do
      subclass = Class.new(simple_options_class)
      options = subclass.from(timeout: 10)
      expect(options).to be_a(subclass)
    end
  end
end
