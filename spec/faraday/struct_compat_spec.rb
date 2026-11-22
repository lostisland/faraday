# frozen_string_literal: true

RSpec.describe Faraday::StructCompat do
  let(:klass) do
    Class.new(Faraday::BaseOptions) do
      include Faraday::StructCompat

      const_set(:MEMBERS, %i[a b].freeze)
      attr_accessor :a
      attr_writer :b

      def b
        @b || 'derived'
      end
    end
  end

  subject(:options) { klass.new(a: false) }

  it 'is not a legacy Options' do
    expect(options).not_to be_a(Faraday::Options)
    expect(options).not_to be_a(Struct)
  end

  describe '#[]' do
    it 'reads members with symbol or string keys, through the accessors' do
      expect(options[:a]).to be(false)
      expect(options['b']).to eq('derived')
    end

    it 'raises NameError on unknown keys' do
      expect { options[:c] }.to raise_error(NameError, "no member 'c' in struct")
    end
  end

  describe '#fetch' do
    it 'returns a set member, even false' do
      expect(options.fetch(:a, true)).to be(false)
    end

    it 'writes and returns the default or the block value when the member is not set' do
      options.a = nil
      expect(options.fetch(:a, 1)).to eq(1)
      expect(options.a).to eq(1)

      options.a = nil
      expect(options.fetch(:a) { |key| "#{key}!" }).to eq('a!')
    end

    it 'raises KeyError without a default' do
      options.a = nil
      expect { options.fetch(:a) }.to raise_error(KeyError, 'key not found: :a')
    end
  end

  describe '#key?' do
    it 'is true for the members that are set' do
      expect(options.key?(:a)).to be(true)
      options.a = nil
      expect(options.key?(:a)).to be(false)
    end

    it 'is false for unknown keys and string keys' do
      expect(options.key?(:c)).to be(false)
      expect(options.key?('a')).to be(false)
    end
  end
end
