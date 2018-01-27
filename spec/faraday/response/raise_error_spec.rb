RSpec.describe Faraday::Response::RaiseError do
  let(:conn) do
    Faraday.new do |b|
      b.response :raise_error
      b.adapter :test do |stub|
        stub.get('ok')        { [200, {'Content-Type' => 'text/html'}, '<body></body>'] }
        stub.get('not-found') { [404, {'X-Reason' => 'because'}, 'keep looking'] }
        stub.get('error')     { [500, {'X-Error' => 'bailout'}, 'fail'] }
      end
    end
  end

  it 'raises no exceptio for 200 responses' do
    expect { conn.get('ok') }.not_to raise_error
  end

  it 'raise Faraday::Error::ResourceNotFound for 404 responses' do
    expect { conn.get('not-found') }.to raise_error(Faraday::Error::ResourceNotFound) do |ex|
      expect(ex.message).to eq('the server responded with status 404')
      expect(ex.response[:headers]['X-Reason']).to eq('because')
    end
  end

  it 'raise Faraday::Error::ClientError for 500 responses' do
    expect { conn.get('error') }.to raise_error(Faraday::Error::ClientError) do |ex|
      expect(ex.message).to eq('the server responded with status 500')
      expect(ex.response[:headers]['X-Error']).to eq('bailout')
    end
  end
end
