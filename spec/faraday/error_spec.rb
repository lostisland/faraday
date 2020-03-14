# frozen_string_literal: true

RSpec.describe Faraday::ClientError do
  describe '.initialize' do
    subject { described_class.new(exception, deprecated_response, response) }
    let(:deprecated_response) { nil }
    let(:response) { nil }

    context 'with exception only' do
      let(:exception) { RuntimeError.new('test') }

      it { expect(subject.wrapped_exception).to eq(exception) }
      it { expect(subject.response).to be_nil }
      it { expect(subject.message).to eq(exception.message) }
      it { expect(subject.backtrace).to eq(exception.backtrace) }
      it { expect(subject.inspect).to eq('#<Faraday::ClientError wrapped=#<RuntimeError: test>>') }
    end

    context 'with deprecated_response hash' do
      let(:exception) { { status: 400 } }

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(exception) }
      it { expect(subject.message).to eq('the server responded with status 400') }
      it { expect(subject.inspect).to eq('#<Faraday::ClientError response={:status=>400}>') }
    end

    context 'with string' do
      let(:exception) { 'custom message' }

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to be_nil }
      it { expect(subject.message).to eq('custom message') }
      it { expect(subject.inspect).to eq('#<Faraday::ClientError #<Faraday::ClientError: custom message>>') }
    end

    context 'with anything else #to_s' do
      let(:exception) { %w[error1 error2] }

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to be_nil }
      it { expect(subject.message).to eq('["error1", "error2"]') }
      it { expect(subject.inspect).to eq('#<Faraday::ClientError #<Faraday::ClientError: ["error1", "error2"]>>') }
    end

    context 'with exception string and deprecated_response hash' do
      let(:exception) { 'custom message' }
      let(:deprecated_response) { { status: 400 } }

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(deprecated_response) }
      it { expect(subject.message).to eq('custom message') }
      it { expect(subject.inspect).to eq('#<Faraday::ClientError response={:status=>400}>') }
    end

    context 'with deprecated_response hash and response' do
      let(:exception) { { status: 400 } }
      let(:env) do
        Faraday::Env.from(status: 400, body: 'yikes',
                          response_headers: { 'Content-Type' => 'text/plain' })
      end
      let(:response) { Faraday::Response.new(env) }

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(exception) }
      it { expect(subject.message).to eq('the server responded with status 400') }
      it { expect(subject.inspect).to eq('#<Faraday::ClientError response={:status=>400}>') }
      it { expect(subject.response_status).to eq(400) }
      it { expect(subject.response_body).to eq('yikes') }
      it { expect(subject.response_headers).to eq({ 'Content-Type' => 'text/plain' }) }
    end
  end
end
