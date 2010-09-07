require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class MultipartTest < Faraday::TestCase
  def setup
    @app = Faraday::Adapter.new nil
    @env = {:request_headers => {}}
  end

  def test_processes_nested_body
    @env[:body] = {:a => 1, :b => Faraday::UploadIO.new(__FILE__, 'text/x-ruby')}
    @app.process_body_for_request @env
    assert_kind_of CompositeReadIO, @env[:body]
    assert_equal "%s;boundary=%s" %
      [Faraday::Adapter::MULTIPART_TYPE, Faraday::Adapter::DEFAULT_BOUNDARY], 
      @env[:request_headers]['Content-Type']
  end

  def test_processes_nil_body
    @env[:body] = nil
    @app.process_body_for_request @env
    assert_nil @env[:body]
  end

  def test_processes_empty_body
    @env[:body] = ''
    @app.process_body_for_request @env
    assert_equal '', @env[:body]
  end

  def test_processes_string_body
    @env[:body] = 'abc'
    @app.process_body_for_request @env
    assert_equal 'abc', @env[:body]
  end
end
