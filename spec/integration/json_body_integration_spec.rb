# frozen_string_literal: true

RSpec.describe 'JSON request bodies' do
  let(:conn) do
    httpbin_connection do |f|
      f.request :json
      f.response :json
    end
  end

  {
    'false' => false,
    'true' => true,
    'an integer' => 42,
    'a float' => 3.14,
    'zero' => 0,
    'an array' => [1, 2],
    'a hash' => { 'a' => 1 }
  }.each do |description, value|
    it "encodes #{description} as a JSON body" do
      response = conn.post('/post', value)

      expect(response.status).to eq(200)
      expect(response.body['data']).to eq(JSON.generate(value))
      expect(response.body['json']).to eq(value)
      expect(response.body['headers']['Content-Type']).to eq('application/json')
    end
  end

  # The JSON middleware leaves String bodies untouched, assuming they are already encoded
  it 'sends a pre-encoded JSON string literal as is' do
    response = conn.post('/post', '"hello"')

    expect(response.body['data']).to eq('"hello"')
    expect(response.body['json']).to eq('hello')
  end

  it 'sends no body when the body is nil' do
    response = conn.post('/post', nil)

    expect(response.body['data']).to eq('')
  end
end
