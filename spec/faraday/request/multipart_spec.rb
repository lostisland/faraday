# frozen_string_literal: true

Faraday::CompositeReadIO.class_eval { attr_reader :ios }

RSpec.describe Faraday::Request::Multipart do
  let(:conn) do
    Faraday.new do |b|
      b.request :multipart
      b.request :url_encoded
      b.adapter :test do |stub|
        stub.post('/echo') do |env|
          posted_as = env[:request_headers]['Content-Type']
          [200, { 'Content-Type' => posted_as }, env[:body]]
        end
      end
    end
  end

  shared_examples 'a multipart request' do
    it 'forms a multipart request' do
      response = conn.post('/echo', payload)

      expect(response.body).to be_a_kind_of(Faraday::CompositeReadIO)
      match = 'multipart/form-data; boundary=%s' % Faraday::Request::Multipart::DEFAULT_BOUNDARY_PREFIX
      expect(response.headers['Content-Type']).to start_with(match)

      response.body.send(:ios).map { |io| io.read }.each do |io|
        re = regexes.detect { |r| io =~ r }
        regexes.delete(re) if re
      end
      expect(regexes).to eq([])
    end

    it 'generates a unique boundary for each request' do
      response1 = conn.post('/echo', payload)
      response2 = conn.post('/echo', payload)
      expect(response1.headers['Content-Type']).not_to eq(response2.headers['Content-Type'])
    end
  end

  context 'when multipart objects in param' do
    let(:regexes) { [/name\=\"a\"/,
                     /name=\"b\[c\]\"\; filename\=\"multipart_spec\.rb\"/,
                     /name=\"b\[d\]\"/] }

    let(:payload) { { :a => 1, :b => { :c => Faraday::UploadIO.new(__FILE__, 'text/x-ruby'), :d => 2 } } }
    it_behaves_like 'a multipart request'
  end

  context 'when multipart objects in array param' do
    let(:regexes) { [/name\=\"a\"/,
                     /name=\"b\[\]\[c\]\"\; filename\=\"multipart_spec\.rb\"/,
                     /name=\"b\[\]\[d\]\"/] }

    let(:payload) { { :a => 1, :b => [{ :c => Faraday::UploadIO.new(__FILE__, 'text/x-ruby'), :d => 2 }] } }
    it_behaves_like 'a multipart request'
  end
end
