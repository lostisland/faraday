# frozen_string_literal: true

require 'rack/utils'

# Decodes a list of nested query shapes with both Faraday and
# Rack::Utils.parse_nested_query and expects the same result.
#
# Each query tests a different behaviour. Before you add one, check that no
# query below already tests the same rule in another order or at another depth.
RSpec.describe Faraday::NestedParamsEncoder, '.decode compared with Rack' do
  # Faraday must decode these exactly as Rack does. If Rack raises, Faraday
  # must raise a TypeError with the same message.
  rack_compatible_queries = [
    # Hashes and arrays nested inside an array element
    'a[][b][c]=d',
    'a[][b][]=x&a[][b][]=y',
    'a[][b][c]=d&a[][b][c]=e',
    'a[][b][c][d]=e',
    'a[][b][]=x&a[][c]=y',
    'a[][b][]=x&a[][c]=y&a[][b][]=z',
    'a[][b][c]=d&a[][e]=f',
    'a[][b][c]=d&a[][b][e]=f',
    'a[][b][c][]=1&a[][b][c][]=2',
    'a[][b][c][]=1&a[][b][d]=2',
    'a[][b][][c]=d&a[][b][][c]=e',
    'a[][b][][c]=d&a[][b][][e]=f',
    # Scalars mixed with nested hashes in one array
    'a[]=1&a[][b][c]=d',
    'a[][b][c]=d&a[]=1',
    # An array of hashes under a hash
    'x[y][][z]=1&x[y][][w]=2&x[y][][z]=3',
    # Empty and missing values
    'a[][b][]=&a[][b][]',
    'a[][b][c]=&a[][b][c]',
    # One key used with two different types
    'a[][b][c]=d&a[][b][]=x',
    'a[][b][]=x&a[][b][c]=d',
    'a[][b][c]=d&a[][b]=1',
    'a[]=x&a[b]=y',
    # Other shapes
    'a[][0]=x',
    'a[][b]c=1'
  ].freeze

  # Faraday decodes these differently from Rack on purpose. Other specs in
  # nested_spec.rb explain each rule. These pin Faraday's result.
  intended_rack_differences = {
    # Numeric indices make an array. Rack makes a hash with string keys.
    'a[0][b]=x&a[1][b]=y' => { 'a' => [{ 'b' => 'x' }, { 'b' => 'y' }] },
    # Repeated array notation counts as one.
    'a[][][b]=c' => { 'a' => [{ 'b' => 'c' }] },
    # Faraday ignores stray brackets.
    'a]=1' => { 'a' => '1' }
  }.freeze

  def decode_outcome
    [:decoded, yield]
  rescue TypeError => e
    # Rack names its own hash class in the message. Faraday says Hash.
    [:raised, e.message.sub('Rack::QueryParser::Params', 'Hash')]
  end

  def faraday_outcome(query)
    decode_outcome { described_class.decode(query) }
  end

  def rack_outcome(query)
    decode_outcome { Rack::Utils.parse_nested_query(query) }
  end

  rack_compatible_queries.each do |query|
    it "decodes #{query} like Rack" do
      expect(faraday_outcome(query)).to eq(rack_outcome(query))
    end
  end

  intended_rack_differences.each do |query, expected|
    it "decodes #{query} differently from Rack" do
      expect(described_class.decode(query)).to eq(expected)
    end
  end
end
