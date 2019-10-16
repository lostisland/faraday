# frozen_string_literal: true

RSpec.describe Faraday::Adapter::Patron do
  features :reason_phrase_parse, :pooling

  it_behaves_like 'an adapter'

  it 'allows to provide adapter specific configs' do
    conn = Faraday.new do |f|
      f.adapter :patron do |session|
        session.max_redirects = 10
        raise 'Configuration block called'
      end
    end

    expect { conn.get('/') }.to raise_error(RuntimeError, 'Configuration block called')
  end
end
