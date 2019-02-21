describe 'making requests with' do
  let(:conn) do
    Faraday::Connection.new(
      url: "http://example.com",
      headers: { 'faraday-conn': '1' },
    )
  end

  let(:method) { nil }

  shared_examples 'method with query' do
    it 'makes request with path' do
      stubbed = stub_request(method, 'http://example.com/a?a=1')
      conn.send(method, '/a', a: 1)
      expect(stubbed).to have_been_made.once
    end

    it 'makes request with block' do
      stubbed = stub_request(method, 'http://example.com/a?a=1')
      conn.send(method, '/a') do |req|
        req.params[:a] = 1
      end
      expect(stubbed).to have_been_made.once
    end
  end

  shared_examples 'method with body' do
    it 'makes request with path' do
      stubbed = stub_request(method, 'http://example.com/a')
      res = conn.send(method, '/a', a: 1)
      expect(res.env.request_body).to eq('a=1')
      expect(stubbed).to have_been_made.once
    end

    it 'makes request with block' do
      stubbed = stub_request(method, 'http://example.com/a?a=1')
      res = conn.send(method, '/a', a: 1) do |req|
        req.params[:a] = 1
      end
      expect(res.env.request_body).to eq('a=1')
      expect(stubbed).to have_been_made.once
    end
  end

  context '#delete' do
    let(:method) { :delete }
    it_behaves_like 'method with query'
  end

  context '#get' do
    let(:method) { :get }
    it_behaves_like 'method with query'
  end

  context '#head' do
    let(:method) { :head }
    it_behaves_like 'method with query'
  end

  context '#options' do
    let(:method) { :options }
    it_behaves_like 'method with query'

    it 'returns connection options with no args' do
      expect(conn.options).to be_a(Faraday::Options)
    end

    it 'makes request with nil path' do
      stubbed = stub_request(method, 'http://example.com')
      conn.send(method, nil)
      expect(stubbed).to have_been_made.once
    end
  end

  context '#patch' do
    let(:method) { :patch }
    it_behaves_like 'method with body'
  end

  context '#post' do
    let(:method) { :post }
    it_behaves_like 'method with body'
  end

  context '#put' do
    let(:method) { :put }
    it_behaves_like 'method with body'
  end
end
