require 'rack/utils'

RSpec.describe Faraday::NestedParamsEncoder do
  it_behaves_like 'a params encoder'

  it 'decodes arrays' do
    query    = 'a[1]=one&a[2]=two&a[3]=three'
    expected = { 'a' => %w(one two three) }
    expect(subject.decode(query)).to eq(expected)
  end

  it 'decodes hashes' do
    query    = 'a[b1]=one&a[b2]=two&a[b][c]=foo'
    expected = { "a" => { "b1" => "one", "b2" => "two", "b" => { "c" => "foo" } } }
    expect(subject.decode(query)).to eq(expected)
  end

  it 'decodes nested arrays rack compat' do
    query    = 'a[][one]=1&a[][two]=2&a[][one]=3&a[][two]=4'
    expected = Rack::Utils.parse_nested_query(query)
    expect(subject.decode(query)).to eq(expected)
  end

  it 'decode_nested_array_mixed_types' do
    query    = 'a[][one]=1&a[]=2&a[]=&a[]'
    expected = Rack::Utils.parse_nested_query(query)
    expect(subject.decode(query)).to eq(expected)
  end

  it 'decode_nested_ignores_invalid_array' do
    query    = '[][a]=1&b=2'
    expected = { "a" => "1", "b" => "2" }
    expect(subject.decode(query)).to eq(expected)
  end

  it 'decode_nested_ignores_repeated_array_notation' do
    query    = 'a[][][]=1'
    expected = { "a" => ["1"] }
    expect(subject.decode(query)).to eq(expected)
  end

  it 'decode_nested_ignores_malformed_keys' do
    query    = '=1&[]=2'
    expected = {}
    expect(subject.decode(query)).to eq(expected)
  end

  it 'decode_nested_subkeys_dont_have_to_be_in_brackets' do
    query    = 'a[b]c[d]e=1'
    expected = { "a" => { "b" => { "c" => { "d" => { "e" => "1" } } } } }
    expect(subject.decode(query)).to eq(expected)
  end

  it 'decode_nested_final_value_overrides_any_type' do
    query    = 'a[b][c]=1&a[b]=2'
    expected = { "a" => { "b" => "2" } }
    expect(subject.decode(query)).to eq(expected)
  end

  it 'encode_rack_compat' do
    params   = { :a => [{ :one => "1", :two => "2" }, "3", ""] }
    result   = Faraday::Utils.unescape(Faraday::NestedParamsEncoder.encode(params)).split('&')
    expected = Rack::Utils.build_nested_query(params).split('&')
    expect(result).to match_array(expected)
  end

  shared_examples 'a wrong decoding' do
    it do
      expect { subject.decode(query) }.to raise_error(TypeError) do |e|
        expect(e.message).to eq(error_message)
      end
    end
  end

  context 'when expecting hash but getting string' do
    let(:query) { 'a=1&a[b]=2' }
    let(:error_message) { "expected Hash (got String) for param `a'" }
    it_behaves_like 'a wrong decoding'
  end

  context 'when expecting hash but getting array' do
    let(:query) { 'a[]=1&a[b]=2' }
    let(:error_message) { "expected Hash (got Array) for param `a'" }
    it_behaves_like 'a wrong decoding'
  end

  context 'when expecting nested hash but getting non nested' do
    let(:query) { 'a[b]=1&a[b][c]=2' }
    let(:error_message) { "expected Hash (got String) for param `b'" }
    it_behaves_like 'a wrong decoding'
  end

  context 'when expecting array but getting hash' do
    let(:query) { 'a[b]=1&a[]=2' }
    let(:error_message) { "expected Array (got Hash) for param `a'" }
    it_behaves_like 'a wrong decoding'
  end

  context 'when expecting array but getting string' do
    let(:query) { 'a=1&a[]=2' }
    let(:error_message) { "expected Array (got String) for param `a'" }
    it_behaves_like 'a wrong decoding'
  end
end