require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class TestConnection < Faraday::TestCase

  def test_adapters_know_they_are_adapters
    assert Faraday::Adapter.adapter?
  end

  def test_middleware_is_not_adapter_by_default
    assert !Faraday::Middleware.adapter?
  end
end
