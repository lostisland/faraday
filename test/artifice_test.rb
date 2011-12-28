require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
require 'rack'

class ArtificeTest < Faraday::TestCase
  class App
    def call(env)
      [200, {'Content-Type' => 'text/plain'}, [env['HTTP_HOST'] || 'artifice']]
    end
  end

  def test_sets_default_adapter
    assert_equal :net_http, Faraday.default_adapter
    Faraday.artifice.activate
    assert_equal :artifice, Faraday.default_adapter
  ensure
    Faraday.artifice.deactivate
  end

  def test_unsets_default_adapter
    assert_equal :net_http, Faraday.default_adapter
    Faraday.artifice.activate
    Faraday.artifice.deactivate
    assert_equal :net_http, Faraday.default_adapter
  ensure
    Faraday.artifice.deactivate
  end

  def test_sets_endpoint
    app = App.new
    Faraday.artifice.activate_with(app) do
      assert_equal app, Faraday::Adapter::Artifice.endpoint
    end
  end

  def test_hits_rack_app
    Faraday.artifice.activate_with(App.new) do
      res = Faraday.new.get('/')
      assert_equal 'artifice', res.body
    end
  end

  def test_dispatches_domains_and_ssl
    app = Rack::Builder.app do
      map("http://one/") { run App.new }
      map("http://two/") { run App.new }
      map("http://three:8080/") { run App.new }
      map("https://four/") { run lambda { |e| [200, {}, [e['HTTPS']]]} }
    end
    Faraday.artifice.activate_with(app) do
      res = Faraday.new(:url => 'http://one').get('/')
      assert_equal 'one', res.body
      res = Faraday.new(:url => 'http://two').get('/')
      assert_equal 'two', res.body
      res = Faraday.new(:url => 'http://three:8080').get('/')
      assert_equal 'three', res.body
      res = Faraday.new(:url => 'https://four').get('/')
      assert_equal 'on', res.body
    end
  end

end