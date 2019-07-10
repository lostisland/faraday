require 'faraday'
require 'json'

class Client
  def initialize(conn)
    @conn = conn
  end

  def sushi(jname)
    res = @conn.get("/#{jname}")
    data = JSON.parse(res.body)
    data['name']
  end
end

describe Client do
  let(:stubs)  { Faraday::Adapter::Test::Stubs.new }
  let(:conn)   { Faraday.new { |b| b.adapter(:test, stubs) } }
  let(:client) { Client.new(conn) }

  it 'parses name' do
    stubs.get('/ebi') do |env|
      [
        200,
        { 'Content-Type': 'application/javascript' },
        '{"name": "shrimp"}'
      ]
    end

    # fails because of stubs.verify_stubbed_calls
    stubs.get('/unused') { [404, {}, ''] }

    expect(client.sushi('ebi')).to eq('shrimp')
    stubs.verify_stubbed_calls
  end

  it "handles 404" do
    stubs.get('/ebi') do |env|
      [
        404,
        { 'Content-Type': 'application/javascript' },
        '{}'
      ]
    end
    expect(client.sushi('ebi')).to be_nil
    stubs.verify_stubbed_calls
  end
end
