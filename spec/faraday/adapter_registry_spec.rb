# frozen_string_literal: true

RSpec.describe Faraday::AdapterRegistry do
  describe '.initialize' do
    subject { described_class.new }

    it { expect { subject.get(:FinFangFoom) }.to raise_error(NameError) }
    it { expect { subject.get('FinFangFoom') }.to raise_error(NameError) }

    it 'looks up class by string name' do
      expect(subject.get('Faraday::Connection')).to eq(Faraday::Connection)
    end

    it 'looks up class by symbol name' do
      expect(subject.get(:Faraday)).to eq(Faraday)
    end

    it 'caches lookups with implicit name' do
      subject.set :symbol
      expect(subject.get('symbol')).to eq(:symbol)
    end

    it 'caches lookups with explicit name' do
      subject.set 'string', :name
      expect(subject.get(:name)).to eq('string')
    end
  end
end
