# frozen_string_literal: true

RSpec.describe Faraday::Adapter::Test do
  let(:stubs) do
    described_class::Stubs.new do |stub|
      stub.get('http://domain.test/hello') do
        [200, { 'Content-Type' => 'text/html' }, 'domain: hello']
      end

      stub.get('http://wrong.test/hello') do
        [200, { 'Content-Type' => 'text/html' }, 'wrong: hello']
      end

      stub.get('http://wrong.test/bait') do
        [404, { 'Content-Type' => 'text/html' }]
      end

      stub.get('/hello') do
        [200, { 'Content-Type' => 'text/html' }, 'hello']
      end

      stub.get('/method-echo') do |env|
        [200, { 'Content-Type' => 'text/html' }, env[:method].to_s]
      end

      stub.get(%r{\A/resources/\d+(?:\?|\z)}) do
        [200, { 'Content-Type' => 'text/html' }, 'show']
      end

      stub.get(%r{\A/resources/(specified)\z}) do |_env, meta|
        [200, { 'Content-Type' => 'text/html' }, "show #{meta[:match_data][1]}"]
      end

      stub.get('foo.json') do
        [200, { 'Content-Type' => 'application/json' }, { a: 1 }]
      end
    end
  end

  let(:connection) do
    Faraday.new(url: 'https://sushi.com/api') do |builder|
      builder.adapter :test, stubs
    end
  end

  let(:response) { make_request }
  let(:request_url) { '/hello' }
  let(:request_block) { nil }
  let(:status) { response.status }
  let(:headers) { response.headers }
  let(:body) { response.body }

  def make_request
    connection.get(request_url, &request_block)
  end

  context 'with simple path sets status' do
    subject { status }

    it { is_expected.to eq 200 }
  end

  context 'with simple path sets headers' do
    subject { headers['Content-Type'] }

    it { is_expected.to eq 'text/html' }
  end

  context 'with simple path sets body' do
    subject { body }

    it { is_expected.to eq 'hello' }
  end

  context 'with host points to the right stub' do
    subject { body }

    let(:request_url) { 'http://domain.test/hello' }

    it { is_expected.to eq 'domain: hello' }
  end

  describe 'can be called several times' do
    subject { body }

    before do
      make_request
    end

    it { is_expected.to eq 'hello' }
  end

  describe 'can handle regular expression path' do
    subject { body }

    let(:request_url) { '/resources/1' }

    it { is_expected.to eq 'show' }
  end

  describe 'can handle single parameter block' do
    subject { body }

    let(:request_url) { '/method-echo' }

    it { is_expected.to eq 'get' }
  end

  describe 'can handle regular expression path with captured result' do
    subject { body }

    let(:request_url) { '/resources/specified' }

    it { is_expected.to eq 'show specified' }
  end

  context 'with get params' do
    subject { body }

    before do
      stubs.get('/param?a=1') { [200, {}, 'a'] }
    end

    let(:request_url) { '/param?a=1' }

    it { is_expected.to eq 'a' }
  end

  describe 'ignoring unspecified get params' do
    before do
      stubs.get('/optional?a=1') { [200, {}, 'a'] }
    end

    context 'with multiple params' do
      subject { body }

      let(:request_url) { '/optional?a=1&b=1' }

      it { is_expected.to eq 'a' }
    end

    context 'with single param' do
      subject { body }

      let(:request_url) { '/optional?a=1' }

      it { is_expected.to eq 'a' }
    end

    context 'without params' do
      let(:request_url) { '/optional' }

      it do
        expect { response }.to raise_error(
          Faraday::Adapter::Test::Stubs::NotFound
        )
      end
    end
  end

  context 'with http headers' do
    before do
      stubs.get('/yo', 'X-HELLO' => 'hello') { [200, {}, 'a'] }
      stubs.get('/yo') { [200, {}, 'b'] }
    end

    let(:request_url) { '/yo' }

    context 'with header' do
      subject { body }

      let(:request_block) { proc { |env| env.headers['X-HELLO'] = 'hello' } }

      it { is_expected.to eq 'a' }
    end

    context 'without header' do
      subject { body }

      it { is_expected.to eq 'b' }
    end
  end

  describe 'request to relative path' do
    subject { body }

    let(:request_url) { 'foo.json' }

    it { is_expected.to eq a: 1 }

    context 'when stubbed only absolute path' do
      let(:request_url) { 'hello' }

      it { expect { response }.to raise_error described_class::Stubs::NotFound }
    end
  end

  describe 'different outcomes for the same request' do
    subject { body }

    before do
      stubs.get('/foo') { [200, { 'Content-Type' => 'text/html' }, 'hello'] }
      stubs.get('/foo') { [200, { 'Content-Type' => 'text/html' }, 'world'] }
    end

    let(:request_url) { '/foo' }

    describe 'the first request' do
      it { is_expected.to eq 'hello' }
    end

    describe 'the second request' do
      before do
        make_request
      end

      it { is_expected.to eq 'world' }
    end
  end

  describe 'yielding env to stubs' do
    let(:request_url) { 'http://foo.com/foo?a=1' }

    attr_reader :env

    before do
      stubs.get '/foo' do |env|
        @env = env
      end

      connection.headers['Accept'] = 'text/plain'

      make_request
    end

    describe 'path' do
      subject { env[:url].path }

      it { is_expected.to eq '/foo' }
    end

    describe 'host' do
      subject { env[:url].host }

      it { is_expected.to eq 'foo.com' }
    end

    describe 'params' do
      subject { env[:params] }

      it { is_expected.to eq 'a' => '1' }
    end

    describe 'request headers' do
      subject { env[:request_headers] }

      it { is_expected.to include 'Accept' => 'text/plain' }
    end
  end

  describe 'params parsing' do
    subject { body }

    let(:request_url) { 'http://foo.com/foo?a[b]=1' }

    attr_reader :env

    before do
      stubs.get '/foo' do |env|
        @env = env
      end

      connection.options.params_encoder = params_encoder if params_encoder

      make_request
    end

    context 'with default encoder' do
      let(:params_encoder) {}

      describe 'nested param' do
        subject { env[:params]['a']['b'] }

        it { is_expected.to eq '1' }
      end
    end

    context 'with nested encoder' do
      let(:params_encoder) { Faraday::NestedParamsEncoder }

      describe 'nested param' do
        subject { env[:params]['a']['b'] }

        it { is_expected.to eq '1' }
      end
    end

    context 'with flat encoder' do
      let(:params_encoder) { Faraday::FlatParamsEncoder }

      describe 'root param' do
        subject { env[:params]['a[b]'] }

        it { is_expected.to eq '1' }
      end
    end
  end

  describe 'raising an error if no stub was found' do
    describe 'for request' do
      let(:request_url) { '/invalid' }
      let(:request_block) { proc { [200, {}, []] } }

      it { expect { response }.to raise_error described_class::Stubs::NotFound }
    end

    describe 'for specified host' do
      let(:request_url) { 'http://domain.test/bait' }

      it { expect { response }.to raise_error described_class::Stubs::NotFound }
    end

    describe 'for request without specified header' do
      let(:request_url) { '/yo' }

      before do
        stubs.get('/yo', 'X-HELLO' => 'hello') { [200, {}, 'a'] }
      end

      it { expect { response }.to raise_error described_class::Stubs::NotFound }
    end
  end
end
