# frozen_string_literal: true

require 'rack/utils'

RSpec.describe Faraday::NestedParamsEncoder do
  it_behaves_like 'a params encoder'

  around do |example|
    original_param_depth_limit = described_class.param_depth_limit
    example.run
  ensure
    described_class.param_depth_limit = original_param_depth_limit
  end

  it 'decodes arrays' do
    query    = 'a[1]=one&a[2]=two&a[3]=three'
    expected = { 'a' => %w[one two three] }
    expect(subject.decode(query)).to eq(expected)
  end

  it 'decodes hashes' do
    query    = 'a[b1]=one&a[b2]=two&a[b][c]=foo'
    expected = { 'a' => { 'b1' => 'one', 'b2' => 'two', 'b' => { 'c' => 'foo' } } }
    expect(subject.decode(query)).to eq(expected)
  end

  it 'decodes nested arrays rack compat' do
    query    = 'a[][one]=1&a[][two]=2&a[][one]=3&a[][two]=4'
    expected = Rack::Utils.parse_nested_query(query)
    expect(subject.decode(query)).to eq(expected)
  end

  it 'decodes nested array mixed types' do
    query    = 'a[][one]=1&a[]=2&a[]=&a[]'
    expected = Rack::Utils.parse_nested_query(query)
    expect(subject.decode(query)).to eq(expected)
  end

  it 'decodes nested ignores invalid array' do
    query    = '[][a]=1&b=2'
    expected = { 'a' => '1', 'b' => '2' }
    expect(subject.decode(query)).to eq(expected)
  end

  it 'decodes nested ignores repeated array notation' do
    query    = 'a[][][]=1'
    expected = { 'a' => ['1'] }
    expect(subject.decode(query)).to eq(expected)
  end

  it 'decodes nested ignores malformed keys' do
    query    = '=1&[]=2'
    expected = {}
    expect(subject.decode(query)).to eq(expected)
  end

  it 'decodes nested subkeys dont have to be in brackets' do
    query    = 'a[b]c[d]e=1'
    expected = { 'a' => { 'b' => { 'c' => { 'd' => { 'e' => '1' } } } } }
    expect(subject.decode(query)).to eq(expected)
  end

  it 'allows nested params within the configured depth limit' do
    described_class.param_depth_limit = 3

    expect(subject.decode('a[b][c]=1')).to eq({ 'a' => { 'b' => { 'c' => '1' } } })
  end

  it 'raises a controlled error when nested params exceed the depth limit' do
    described_class.param_depth_limit = 2

    expect { subject.decode('a[b][c]=1') }.to raise_error(
      Faraday::Error,
      'exceeded nested parameter depth limit of 2'
    )
  end

  it 'allows disabling the nested params depth limit' do
    described_class.param_depth_limit = nil

    expect(subject.decode('a[b][c][d]=1')).to eq({ 'a' => { 'b' => { 'c' => { 'd' => '1' } } } })
  end

  it 'decodes nested final value overrides any type' do
    query    = 'a[b][c]=1&a[b]=2'
    expected = { 'a' => { 'b' => '2' } }
    expect(subject.decode(query)).to eq(expected)
  end

  it 'encodes rack compat' do
    params   = { a: [{ one: '1', two: '2' }, '3', ''] }
    result   = Faraday::Utils.unescape(Faraday::NestedParamsEncoder.encode(params)).split('&')
    escaped = Rack::Utils.build_nested_query(params)
    expected = Rack::Utils.unescape(escaped).split('&')
    expect(result).to match_array(expected)
  end

  it 'encodes empty string array value' do
    expected = 'baz=&foo%5Bbar%5D='
    result = Faraday::NestedParamsEncoder.encode(foo: { bar: '' }, baz: '')
    expect(result).to eq(expected)
  end

  it 'encodes nil array value' do
    expected = 'baz&foo%5Bbar%5D'
    result = Faraday::NestedParamsEncoder.encode(foo: { bar: nil }, baz: nil)
    expect(result).to eq(expected)
  end

  it 'encodes empty array value' do
    expected = 'baz%5B%5D&foo%5Bbar%5D%5B%5D'
    result = Faraday::NestedParamsEncoder.encode(foo: { bar: [] }, baz: [])
    expect(result).to eq(expected)
  end

  it 'encodes boolean values' do
    params = { a: true, b: false }
    expect(subject.encode(params)).to eq('a=true&b=false')
  end

  it 'encodes boolean values in array' do
    params = { a: [true, false] }
    expect(subject.encode(params)).to eq('a%5B%5D=true&a%5B%5D=false')
  end

  it 'encodes unsorted when asked' do
    params = { b: false, a: true }
    expect(subject.encode(params)).to eq('a=true&b=false')
    Faraday::NestedParamsEncoder.sort_params = false
    expect(subject.encode(params)).to eq('b=false&a=true')
    Faraday::NestedParamsEncoder.sort_params = true
  end

  it 'encodes arrays indices when asked' do
    params = { a: [0, 1, 2] }
    expect(subject.encode(params)).to eq('a%5B%5D=0&a%5B%5D=1&a%5B%5D=2')
    Faraday::NestedParamsEncoder.array_indices = true
    expect(subject.encode(params)).to eq('a%5B0%5D=0&a%5B1%5D=1&a%5B2%5D=2')
    Faraday::NestedParamsEncoder.array_indices = false
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
