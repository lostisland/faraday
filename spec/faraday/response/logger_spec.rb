require 'stringio'
require 'logger'

RSpec.describe Faraday::Response::Logger do
  let(:string_io) { StringIO.new }
  let(:logger) { Logger.new(string_io) }
  let(:logger_options) { {} }
  let(:conn) do
    rubbles = ['Barney', 'Betty', 'Bam Bam']

    Faraday.new do |b|
      b.response :logger, logger, logger_options do |logger|
        logger.filter(/(soylent green is) (.+)/, '\1 tasty')
        logger.filter(/(api_key:).*"(.+)."/, '\1[API_KEY]')
        logger.filter(/(password)=(.+)/, '\1=[HIDDEN]')
      end
      b.adapter :test do |stubs|
        stubs.get('/hello') { [200, { 'Content-Type' => 'text/html' }, 'hello'] }
        stubs.post('/ohai') { [200, { 'Content-Type' => 'text/html' }, 'fred'] }
        stubs.post('/ohyes') { [200, { 'Content-Type' => 'text/html' }, 'pebbles'] }
        stubs.get('/rubbles') { [200, { 'Content-Type' => 'application/json' }, rubbles] }
        stubs.get('/filtered_body') { [200, { 'Content-Type' => 'text/html' }, 'soylent green is people'] }
        stubs.get('/filtered_headers') { [200, { 'Content-Type' => 'text/html' }, 'headers response'] }
        stubs.get('/filtered_params') { [200, { 'Content-Type' => 'text/html' }, 'params response'] }
        stubs.get('/filtered_url') { [200, { 'Content-Type' => 'text/html' }, 'url response'] }
      end
    end
  end

  before do
    logger.level = Logger::DEBUG
  end

  it 'still returns output' do
    resp = conn.get '/hello', nil, accept: 'text/html'
    expect(resp.body).to eq('hello')
  end

  it 'logs method and url' do
    conn.get '/hello', nil, accept: 'text/html'
    expect(string_io.string).to match("get http:/hello")
  end

  it 'logs request headers by default' do
    conn.get '/hello', nil, accept: 'text/html'
    expect(string_io.string).to match(%(Accept: "text/html))
  end

  it 'logs response headers by default' do
    conn.get '/hello', nil, accept: 'text/html'
    expect(string_io.string).to match(%(Content-Type: "text/html))
  end

  it 'does not log request body by default' do
    conn.post '/ohai', 'name=Unagi', accept: 'text/html'
    expect(string_io.string).not_to match(%(name=Unagi))
  end

  it 'does not log response body by default' do
    conn.post '/ohai', 'name=Toro', accept: 'text/html'
    expect(string_io.string).not_to match(%(fred))
  end

  it 'logs filter headers' do
    conn.headers = { 'api_key' => 'ABC123' }
    conn.get '/filtered_headers', nil, accept: 'text/html'
    expect(string_io.string).to match(%(api_key:))
    expect(string_io.string).to match(%([API_KEY]))
    expect(string_io.string).not_to match(%(ABC123))
  end

  it 'logs filter url' do
    conn.get '/filtered_url?password=hunter2', nil, accept: 'text/html'
    expect(string_io.string).to match(%([HIDDEN]))
    expect(string_io.string).not_to match(%(hunter2))
  end

  context 'when not logging request headers' do
    let(:logger_options) { { headers: { request: false } } }

    it 'does not log request headers if option is false' do
      conn.get '/hello', nil, accept: 'text/html'
      expect(string_io.string).not_to match(%(Accept: "text/html))
    end
  end

  context 'when not logging response headers' do
    let(:logger_options) { { headers: { response: false } } }

    it 'does log response headers if option is false' do
      conn.get '/hello', nil, accept: 'text/html'
      expect(string_io.string).not_to match(%(Content-Type: "text/html))
    end
  end

  context 'when logging request body' do
    let(:logger_options) { { bodies: { request: true } } }

    it 'log only request body' do
      conn.post '/ohyes', 'name=Tamago', accept: 'text/html'
      expect(string_io.string).to match(%(name=Tamago))
      expect(string_io.string).not_to match(%(pebbles))
    end
  end

  context 'when logging response body' do
    let(:logger_options) { { bodies: { response: true } } }

    it 'log only response body' do
      conn.post '/ohyes', 'name=Hamachi', accept: 'text/html'
      expect(string_io.string).to match(%(pebbles))
      expect(string_io.string).not_to match(%(name=Hamachi))
    end
  end

  context 'when logging request and response bodies' do
    let(:logger_options) { { bodies: true } }

    it 'log request and response body' do
      conn.post '/ohyes', 'name=Ebi', accept: 'text/html'
      expect(string_io.string).to match(%(name=Ebi))
      expect(string_io.string).to match(%(pebbles))
    end

    it 'log response body object' do
      conn.get '/rubbles', nil, accept: 'text/html'
      expect(string_io.string).to match(%([\"Barney\", \"Betty\", \"Bam Bam\"]\n))
    end

    it 'logs filter body' do
      conn.get '/filtered_body', nil, accept: 'text/html'
      expect(string_io.string).to match(%(soylent green is))
      expect(string_io.string).to match(%(tasty))
      expect(string_io.string).not_to match(%(people))
    end
  end
end
