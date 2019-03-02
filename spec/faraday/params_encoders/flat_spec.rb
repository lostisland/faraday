# frozen_string_literal: true

require 'rack/utils'

RSpec.describe Faraday::FlatParamsEncoder do
  it_behaves_like 'a params encoder'

  it 'decodes arrays' do
    query = 'a=one&a=two&a=three'
    expected = { 'a' => %w[one two three] }
    expect(subject.decode(query)).to eq(expected)
  end
end
