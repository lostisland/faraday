RSpec.describe Faraday::Response do
  subject { Faraday::Response.new.finish(params) }

  let(:params) do
    { status: 404, body: 'yikes', headers: { 'Content-Type' => 'text/plain' }, reason_phrase: 'not found' }
  end

  it { expect(subject.finished?).to be_truthy }
  it { expect { subject.finish({}) }.to raise_error(RuntimeError) }
  it { expect(subject.success?).to be_falsey }
  it { expect(subject.status).to eq(404) }
  it { expect(subject.body).to eq('yikes') }
  it { expect(subject.headers['Content-Type']).to eq('text/plain') }
  it { expect(subject['content-type']).to eq('text/plain') }

  describe '#apply_params' do
    subject { Faraday::Response.new }
    before { subject.apply_params(body: 'yikes', status: 200) }

    it { expect(subject.body).to eq('yikes') }
    it { expect(subject.status).to eq(200) }
  end

  describe 'marshal serialization support' do
    subject { Faraday::Response.new }
    let(:loaded) { Marshal.load(Marshal.dump(subject)) }

    before do
      subject.on_complete {}
      subject.finish(params)
    end

    it { expect(loaded.body).to eq(params[:body]) }
    it { expect(loaded.headers).to eq(params[:headers]) }
    it { expect(loaded.status).to eq(params[:status]) }
    it { expect(loaded.reason_phrase).to eq(params[:reason_phrase]) }
  end

  describe '#on_complete' do
    subject { Faraday::Response.new }

    it 'parse body on finish' do
      subject.on_complete { |response| response.body = response.body.upcase }
      subject.finish(params)

      expect(subject.body).to eq('YIKES')
    end

    it 'can access response body in on_complete callback' do
      subject.on_complete { |response| response.body = subject.body.upcase }
      subject.finish(params)

      expect(subject.body).to eq('YIKES')
    end

    it 'can access response in on_complete callback' do
      callback_response = nil
      subject.on_complete { |response| callback_response = response }
      subject.finish({})

      expect(subject).to eq(callback_response)
    end
  end
end
