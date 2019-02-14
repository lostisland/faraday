RSpec.describe Faraday::Env do
  it 'allows to access members' do
    expect(subject.method).to be_nil
    subject.method = :get
    expect(subject.method).to eq(:get)
  end

  it 'allows to access symbol non members' do
    expect(subject[:custom]).to be_nil
    subject[:custom] = :boom
    expect(subject[:custom]).to eq(:boom)
  end

  it 'allows to access string non members' do
    expect(subject['custom']).to be_nil
    subject['custom'] = :boom
    expect(subject['custom']).to eq(:boom)
  end

  it 'ignores false when fetching' do
    ssl = Faraday::SSLOptions.new
    ssl.verify = false
    expect(ssl.fetch(:verify, true)).to be_falsey
  end

  it 'retains custom members' do
    subject[:foo] = "custom 1"
    subject[:bar] = :custom_2
    env2 = Faraday::Env.from(subject)
    env2[:baz] = "custom 3"

    expect(env2[:foo]).to eq("custom 1")
    expect(env2[:bar]).to eq(:custom_2)
    expect(subject[:baz]).to be_nil
  end

  describe '#body' do
    subject { Faraday::Env.from(body: { foo: 'bar' }) }

    context 'when response is not finished yet' do
      it 'returns the request body' do
        expect(subject.body).to eq({ foo: 'bar' })
      end
    end

    context 'when response is finished' do
      before { subject.response = Faraday::Response.new.finish(body: { bar: 'foo' }) }

      it 'returns the response body' do
        expect(subject.body).to eq({ bar: 'foo' })
      end

      it 'allows to access request_body' do
        expect(subject.request_body).to eq({ foo: 'bar' })
      end

      it 'allows to access response_body' do
        expect(subject.response_body).to eq({ bar: 'foo' })
      end
    end
  end
end