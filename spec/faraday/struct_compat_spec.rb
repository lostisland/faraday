# frozen_string_literal: true

RSpec.describe Faraday::StructCompat do
  let(:klass) do
    Class.new(Faraday::BaseOptions) do
      include Faraday::StructCompat

      const_set(:MEMBERS, %i[a b nested].freeze)
      const_set(:COERCIONS, { nested: Faraday::SSLOptions }.freeze)
      attr_accessor :a, :b, :nested

      def self.to_s
        'Compat'
      end
    end
  end

  subject(:options) { klass.new(a: 1, b: false) }

  it 'is a BaseOptions that still looks like the legacy Options' do
    expect(klass.superclass).to eq(Faraday::BaseOptions)
    expect(options).to be_a(Faraday::Options)
    expect(Faraday::Options === options).to be(true) # rubocop:disable Style/CaseEquality
    expect(options).to be_a(Enumerable)
    expect(Faraday::BaseOptions.new).not_to be_a(Faraday::Options)
  end

  describe 'construction' do
    it 'accepts an options hash, nil or members in order' do
      expect(klass.new(a: 1).a).to eq(1)
      expect(klass.new(nil).to_hash).to eq({})
      expect(klass.new(1, 2).to_hash).to eq(a: 1, b: 2)
      expect(klass.new('x').a).to eq('x')
    end

    it 'does not coerce positional members' do
      expect(klass.new(1, 2, { verify: false }).nested).to eq(verify: false)
    end

    it 'raises with too many members' do
      expect { klass.new(1, 2, 3, 4) }.to raise_error(ArgumentError, 'struct size differs')
    end

    it 'builds an empty instance from a falsy value and copies instances' do
      expect(klass.from(false).to_hash).to eq({})
      expect(klass.from(nil).to_hash).to eq({})
      expect(klass.from(options)).to eq(options)
      expect(klass.from(options)).not_to equal(options)
    end

    it 'shares objects with deep_dup and from(instance), copying hashes shallowly' do
      object = Object.new
      options.update(a: object, b: { x: { y: 1 } })
      [options.deep_dup, klass.from(options)].each do |copy|
        expect(copy.a).to equal(object)
        expect(copy.b).not_to equal(options.b)
        expect(copy.b[:x]).to equal(options.b[:x])
      end
    end
  end

  describe 'access' do
    it 'reads and writes with [] and []=' do
      expect(options[:a]).to eq(1)
      expect(options['b']).to be(false)
      options['a'] = 3
      options[1] = 4
      expect(options.to_hash).to eq(a: 3, b: 4)
    end

    it 'raises on unknown members' do
      expect { options[:z] }.to raise_error(NameError, "no member 'z' in struct")
      expect { options[:z] = 1 }.to raise_error(NameError)
      expect { options[5] = 1 }.to raise_error(IndexError)
      expect { options[0] }.to raise_error(NoMethodError)
    end

    it 'goes through the accessors' do
      overriding = Class.new(klass) { def a = 'overridden' }
      expect(overriding.new(a: 1)[:a]).to eq('overridden')
    end

    it 'writes the default of fetch when the member is not set' do
      expect(options.fetch(:a, 9)).to eq(1)
      expect(options.fetch(:b, true)).to be(false)
      expect(options.fetch(:nested, 'x')).to eq('x')
      expect(options.nested).to eq('x')
      expect(options.fetch('a')).to eq(1)
    end

    it 'writes the block value of fetch when the member is not set' do
      expect(options.fetch(:nested) { |key| key.to_s }).to eq('nested') # rubocop:disable Style/SymbolProc
      expect(options.nested).to eq('nested')
    end

    it 'raises KeyError when fetching a member that is not set without default' do
      expect { options.fetch(:nested) }.to raise_error(KeyError)
      expect { options.fetch(:z, 1) }.to raise_error(NoMethodError)
    end

    it 'digs into the members' do
      options.nested = { verify: [1, 2] }
      expect(options.dig(:nested, :verify, 1)).to eq(2)
      expect(options.dig(:z, :verify)).to be_nil
      expect(klass.new(nested: { verify: 1 }).dig(2, :verify)).to eq(1)
    end
  end

  describe 'introspection' do
    it 'lists members, keys and values' do
      expect(options.members).to eq(%i[a b nested])
      expect(klass.members).to eq(%i[a b nested])
      expect(options.keys).to eq(%i[a b])
      expect(options.values).to eq([1, false, nil])
      expect(options.to_a).to eq([1, false, nil])
      expect(options.values_at(:b, 'a')).to eq([false, 1])
      expect(options.size).to eq(3)
      expect(options.length).to eq(3)
    end

    it 'checks keys and values' do
      expect(options.key?(:a)).to be(true)
      expect(options.has_key?(:b)).to be(true) # rubocop:disable Style/PreferredHashMethods
      expect(options.key?(:nested)).to be(false)
      expect(options.value?(false)).to be(true)
      expect(options.has_value?(7)).to be(false) # rubocop:disable Style/PreferredHashMethods
      expect(options.symbolized_key_set).to eq(Set[:a, :b])
      expect(klass.new).to be_empty
      expect(options).not_to be_empty
    end

    it 'converts to hashes' do
      expect(options.to_h).to eq(a: 1, b: false, nested: nil)
      expect(options.to_h { |k, v| [k.to_s, v] }).to include('a' => 1)
      expect(options.to_hash).to eq(a: 1, b: false)
    end

    it 'keeps nested options in to_hash' do
      options.nested = Faraday::SSLOptions.new(verify: false)
      expect(options.to_hash[:nested]).to be_a(Faraday::SSLOptions)
    end

    it 'supports pattern matching' do
      expect(options.deconstruct).to eq([1, false, nil])
      expect(options.deconstruct_keys([:a])).to eq(a: 1)
      expect(options.deconstruct_keys(nil)).to eq(a: 1, b: false, nested: nil)
    end
  end

  describe 'enumeration' do
    it 'yields all the members for each, each_pair and each_value' do
      expect(options.each.to_a).to eq([[:a, 1], [:b, false], [:nested, nil]])
      expect(options.each_pair.to_a).to eq([[:a, 1], [:b, false], [:nested, nil]])
      expect(options.each_value.to_a).to eq([1, false, nil])
      expect { |b| options.each(&b) }.to yield_successive_args([:a, 1], [:b, false], [:nested, nil])
    end

    it 'yields the keys that are set for each_key' do
      expect(options.each_key.to_a).to eq(%i[a b])
    end

    it 'selects values' do
      expect(options.select(&:itself)).to eq([1])
      expect(options.filter(&:nil?)).to eq([nil])
    end
  end

  describe 'mutation' do
    it 'deletes a member' do
      expect(options.delete(:a)).to eq(1)
      expect(options.a).to be_nil
      expect { options.delete(:z) }.to raise_error(NoMethodError)
    end

    it 'clears all the members' do
      expect(options.clear).to be_a(Array)
      expect(options).to be_empty
    end

    it 'does not coerce with []= or setters' do
      options[:nested] = { verify: false }
      expect(options.nested).to eq(verify: false)
    end

    it 'copies the hashes without a coercion when updating' do
      value = { x: 1 }
      options.update(a: value)
      expect(options.a).not_to equal(value)
      expect(options.merge!(a: value).a).to equal(value)
    end

    it 'merges coerced nested options and replaces everything else' do
      options.update(nested: { verify: false })
      options.a = { x: 1 }
      merged = options.merge(nested: { ca_file: 'f' }, a: { y: 2 })
      expect(merged.nested.to_hash).to eq(verify: false, ca_file: 'f')
      expect(merged.a).to eq(y: 2)
      expect(options.nested.to_hash).to eq(verify: false)
    end

    it 'ignores nil when merging and updating, but not false' do
      expect(options.merge(a: nil).a).to eq(1)
      expect(options.update(a: nil).a).to eq(1)
      expect(options.merge(a: false).a).to be(false)
    end
  end

  describe 'equality' do
    it 'compares the class and the values' do
      expect(options).to eq(klass.new(a: 1, b: false))
      expect(options).to eql(klass.new(a: 1, b: false))
      expect(options.hash).to eq(klass.new(a: 1, b: false).hash)
      expect(options).not_to eq(klass.new(a: 1))
      expect(options).not_to eq(a: 1, b: false)
      expect(options).not_to eq(Class.new(klass).new(a: 1, b: false))
    end
  end

  describe 'display' do
    it 'skips false members in inspect' do
      expect(options.inspect).to eq('#<Compat a=1>')
      expect(klass.new(b: false).inspect).to eq('#<Compat (empty)>')
    end

    it 'lists all the members in to_s, like a Struct' do
      expect(options.to_s).to eq('#<struct Compat a=1, b=false, nested=nil>')
    end
  end
end
