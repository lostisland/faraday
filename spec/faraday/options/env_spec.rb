RSpec.describe Faraday::Env do
  subject { Faraday::Env.new }
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
end