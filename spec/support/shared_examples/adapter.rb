shared_examples 'an adapter' do |**options|
  before { skip } if options[:skip]

  context 'with SSL enabled' do
    before { ENV['SSL'] = 'yes' }
    include_examples 'adapter examples', options
  end

  context 'with SSL disabled' do
    before { ENV['SSL'] = 'no' }
    include_examples 'adapter examples'
  end
end

shared_examples 'adapter examples' do |**options|
  include Faraday::StreamingResponseChecker

  let(:adapter) { described_class.name.split('::').last }

  let(:conn_options) { { headers: { 'X-Faraday-Adapter' => adapter } }.merge(options[:conn_options] || {}) }

  let(:adapter_options) do
    return [] unless options[:adapter_options]

    if options[:adapter_options].is_a?(Array)
      options[:adapter_options]
    else
      [options[:adapter_options]]
    end
  end

  let(:protocol) { ssl_mode? ? 'https' : 'http' }
  let(:remote) { "#{protocol}://example.com" }

  let(:conn) do
    conn_options[:ssl] ||= {}
    conn_options[:ssl][:ca_file] ||= ENV['SSL_FILE']

    Faraday.new(remote, conn_options) do |conn|
      conn.request :multipart
      conn.request :url_encoded
      conn.response :raise_error
      conn.adapter described_class, *adapter_options
    end
  end

  let!(:request_stub) { stub_request(http_method, remote) }

  after do
    expect(request_stub).to have_been_requested unless request_stub.disabled?
  end

  describe '#get' do
    let(:http_method) { :get }

    it_behaves_like 'a request method', :get

    on_feature :body_on_get do
      it 'handles request body' do
        body = { bodyrock: 'true' }
        request_stub.with(body: body)
        conn.get('/') do |req|
          req.body = body
        end
      end
    end
  end

  describe '#post' do
    let(:http_method) { :post }

    it_behaves_like 'a request method', :post
  end

  describe '#put' do
    let(:http_method) { :put }

    it_behaves_like 'a request method', :put
  end

  describe '#delete' do
    let(:http_method) { :delete }

    it_behaves_like 'a request method', :delete
  end

  describe '#patch' do
    let(:http_method) { :patch }

    it_behaves_like 'a request method', :patch
  end

  describe '#head' do
    let(:http_method) { :head }

    it_behaves_like 'a request method', :head
  end

  # TODO: Enable after adding API for options method
  # describe '#options' do
  #   let(:http_method) { :options }
  #
  #   it_behaves_like 'a request method'
  # end
end