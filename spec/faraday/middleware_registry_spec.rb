# frozen_string_literal: true

class CustomMiddleware < Faraday::Middleware
end

RSpec.describe Faraday::MiddlewareRegistry do
  let(:dummy) { Class.new { extend Faraday::MiddlewareRegistry } }

  after { dummy.unregister_middleware(:custom) }

  it 'allows to register with constant' do
    dummy.register_middleware(custom: CustomMiddleware)
    expect(dummy.lookup_middleware(:custom)).to eq(CustomMiddleware)
  end

  it 'allows to register with symbol' do
    dummy.register_middleware(custom: :CustomMiddleware)
    expect(dummy.lookup_middleware(:custom)).to eq(CustomMiddleware)
  end

  it 'allows to register with string' do
    dummy.register_middleware(custom: 'CustomMiddleware')
    expect(dummy.lookup_middleware(:custom)).to eq(CustomMiddleware)
  end

  it 'allows to register with Proc' do
    dummy.register_middleware(custom: -> { CustomMiddleware })
    expect(dummy.lookup_middleware(:custom)).to eq(CustomMiddleware)
  end
end
