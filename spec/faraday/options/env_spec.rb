RSpec.describe Faraday::Env do
  it 'allows to access members' do
    e = Faraday::Env.new
    expect(e.method).to be_nil
    e.method = :get
    expect(e.method).to eq(:get)
  end

  it 'allows to access symbol non members' do
    e = Faraday::Env.new
    expect(e[:custom]).to be_nil
    e[:custom] = :boom
    expect(e[:custom]).to eq(:boom)
  end

  it 'allows to access string non members' do
    e = Faraday::Env.new
    expect(e['custom']).to be_nil
    e['custom'] = :boom
    expect(e['custom']).to eq(:boom)
  end

  it 'ignores false when fetching' do
    ssl = Faraday::SSLOptions.new
    ssl.verify = false
    expect(ssl.fetch(:verify, true)).to be_falsey
  end
end