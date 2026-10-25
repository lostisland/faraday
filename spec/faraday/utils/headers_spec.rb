# frozen_string_literal: true

RSpec.describe Faraday::Utils::Headers do
  subject { Faraday::Utils::Headers.new }

  context 'when Content-Type is set to application/json' do
    before { subject['Content-Type'] = 'application/json' }

    it { expect(subject.keys).to eq(['Content-Type']) }
    it { expect(subject['Content-Type']).to eq('application/json') }
    it { expect(subject['CONTENT-TYPE']).to eq('application/json') }
    it { expect(subject['content-type']).to eq('application/json') }
    it { is_expected.to include('content-type') }
  end

  context 'when Content-Type is set to application/xml' do
    before { subject['Content-Type'] = 'application/xml' }

    it { expect(subject.keys).to eq(['Content-Type']) }
    it { expect(subject['Content-Type']).to eq('application/xml') }
    it { expect(subject['CONTENT-TYPE']).to eq('application/xml') }
    it { expect(subject['content-type']).to eq('application/xml') }
    it { is_expected.to include('content-type') }
  end

  describe 'Hash mutators keeping the name index in sync' do
    subject(:headers) { described_class.new('X-Keep' => '1', 'X-Drop' => '2', 'X-Nil' => nil) }

    def expect_dropped(name)
      expect(headers).not_to include(name)
      expect(headers[name]).to be_nil
      expect(headers['x-keep']).to eq('1')
    end

    it '#store behaves like #[]=' do
      headers.store(:x_new, 'v')

      expect(headers['X-New']).to eq('v')
      expect(headers['x-new']).to eq('v')
    end

    it '#clear forgets every name' do
      headers.clear

      expect(headers).to be_empty
      expect(headers).not_to include('x-keep')
      headers['x-keep'] = 'again'
      expect(headers.keys).to eq(['x-keep'])
    end

    it '#shift forgets the removed name' do
      removed, = headers.shift

      expect(headers).not_to include(removed)
      expect(headers[removed]).to be_nil
    end

    it '#compact! forgets names whose value was removed' do
      headers.compact!

      expect(headers).not_to include('x-nil')
      expect(headers['x-keep']).to eq('1')
    end

    it '#delete_if forgets deleted names' do
      headers.delete_if { |key, _| key == 'X-Drop' }
      expect_dropped('x-drop')
    end

    it '#reject! forgets rejected names' do
      headers.reject! { |key, _| key == 'X-Drop' }
      expect_dropped('x-drop')
    end

    it '#keep_if forgets names that were not kept' do
      headers.keep_if { |key, _| key == 'X-Keep' }

      expect(headers.keys).to eq(['X-Keep'])
      expect(headers).not_to include('x-drop')
    end

    it '#select! and #filter! forget names that were not selected' do
      headers.select! { |key, _| key == 'X-Keep' }
      expect(headers).not_to include('x-drop')

      headers['X-Other'] = '3'
      headers.filter! { |key, _| key == 'X-Keep' }
      expect(headers).not_to include('x-other')
    end

    it '#transform_keys! with a block re-indexes the new names' do
      headers.transform_keys!(&:downcase)

      expect(headers.keys).to eq(%w[x-keep x-drop x-nil])
      expect(headers['X-KEEP']).to eq('1')
    end

    it '#transform_keys! with a mapping re-indexes the new names' do
      headers.transform_keys!('X-Drop' => 'Y-Renamed')

      expect(headers['y-renamed']).to eq('2')
      expect(headers).not_to include('x-drop')
    end

    it '#rehash keeps lookups working' do
      expect { headers.rehash }.not_to(change { headers['x-keep'] })
    end

    %i[delete_if reject!].each do |method|
      it "##{method} keeps the index in sync when the block raises" do
        expect do
          headers.public_send(method) { |key, _| key == 'X-Drop' ? raise('boom') : key == 'X-Keep' }
        end.to raise_error('boom')

        # X-Keep was already removed before the block raised on X-Drop.
        expect(headers.keys).to eq(%w[X-Drop X-Nil])
        expect(headers).not_to include('x-keep')
        expect(headers['x-drop']).to eq('2')
      end

      it "##{method} keeps the index in sync when the block breaks out" do
        headers.public_send(method) do |key, _|
          break if key == 'X-Drop'

          true
        end

        expect(headers.keys).to eq(%w[X-Drop X-Nil])
        expect(headers).not_to include('x-keep')
        expect(headers['x-drop']).to eq('2')
      end
    end

    describe 'avoiding a redundant index rebuild' do
      def expect_rebuilds(count)
        expect(headers).to receive(:rebuild_names).exactly(count).times.and_call_original
        yield
      end

      %i[delete_if keep_if reject! select! filter!].each do |method|
        it "##{method} does not rebuild when called without a block" do
          expect_rebuilds(0) { headers.public_send(method) }
        end

        it "##{method} rebuilds once when called with a block" do
          expect_rebuilds(1) { headers.public_send(method) { true } }
        end

        it "##{method} rebuilds once in total when its enumerator is iterated" do
          expect_rebuilds(1) { headers.public_send(method).each { |key| key == 'X-Keep' } }
        end
      end

      it '#transform_keys! does not rebuild when called without a block or mapping' do
        expect_rebuilds(0) { headers.transform_keys! }
      end

      it '#transform_keys! rebuilds once when iterating its enumerator' do
        expect_rebuilds(1) { headers.transform_keys!.each(&:downcase) }
      end

      it '#transform_keys! rebuilds once when given a mapping' do
        expect_rebuilds(1) { headers.transform_keys!('X-Drop' => 'Y-Renamed') }
      end

      it '#transform_keys! rebuilds once when given a block' do
        expect_rebuilds(1) { headers.transform_keys!(&:downcase) }
      end

      %i[shift compact! rehash].each do |method|
        it "##{method} rebuilds once" do
          expect_rebuilds(1) { headers.public_send(method) }
        end
      end
    end
  end

  describe '#fetch' do
    before { subject['Content-Type'] = 'application/json' }

    it { expect(subject.fetch('Content-Type')).to eq('application/json') }
    it { expect(subject.fetch('CONTENT-TYPE')).to eq('application/json') }
    it { expect(subject.fetch(:content_type)).to eq('application/json') }
    it { expect(subject.fetch('invalid', 'default')).to eq('default') }
    it { expect(subject.fetch('invalid', false)).to eq(false) }
    it { expect(subject.fetch('invalid', nil)).to be_nil }
    it { expect(subject.fetch('Invalid') { |key| "#{key} key" }).to eq('Invalid key') }
    it 'calls a block when provided' do
      block_called = false
      expect(subject.fetch('content-type') { block_called = true }).to eq('application/json')
      expect(block_called).to be_falsey
    end
    it 'raises an error if key not found' do
      expected_error = defined?(KeyError) ? KeyError : IndexError
      expect { subject.fetch('invalid') }.to raise_error(expected_error)
    end
  end

  describe '#delete' do
    before do
      subject['Content-Type'] = 'application/json'
      @deleted = subject.delete('content-type')
    end

    it { expect(@deleted).to eq('application/json') }
    it { expect(subject.size).to eq(0) }
    it { is_expected.not_to include('content-type') }
    it { expect(subject.delete('content-type')).to be_nil }
  end

  describe '#dig' do
    before { subject['Content-Type'] = 'application/json' }

    it { expect(subject&.dig('Content-Type')).to eq('application/json') }
    it { expect(subject&.dig('CONTENT-TYPE')).to eq('application/json') }
    it { expect(subject&.dig(:content_type)).to eq('application/json') }
    it { expect(subject&.dig('invalid')).to be_nil }
  end

  describe '#parse' do
    context 'when response headers leave http status line out' do
      let(:headers) { "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n" }

      before { subject.parse(headers) }

      it { expect(subject.keys).to eq(%w[Content-Type]) }
      it { expect(subject['Content-Type']).to eq('text/html') }
      it { expect(subject['content-type']).to eq('text/html') }
    end

    context 'when response headers values include a colon' do
      let(:headers) { "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nLocation: http://httpbingo.org/\r\n\r\n" }

      before { subject.parse(headers) }

      it { expect(subject['location']).to eq('http://httpbingo.org/') }
    end

    context 'when response headers include a blank line' do
      let(:headers) { "HTTP/1.1 200 OK\r\n\r\nContent-Type: text/html\r\n\r\n" }

      before { subject.parse(headers) }

      it { expect(subject['content-type']).to eq('text/html') }
    end

    context 'when response headers include already stored keys' do
      let(:headers) { "HTTP/1.1 200 OK\r\nX-Numbers: 123\r\n\r\n" }

      before do
        h = subject
        h[:x_numbers] = 8
        h.parse(headers)
      end

      it do
        expect(subject[:x_numbers]).to eq('8, 123')
      end
    end
  end
end
