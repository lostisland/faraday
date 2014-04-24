require File.expand_path('../helper', __FILE__)

class AuthenticationMiddlewareTest < Faraday::TestCase
  def conn
    Faraday::Connection.new('http://example.net/') do |builder|
      yield(builder)
      builder.adapter :test do |stub|
        %w[
          /auth-echo
          /auth-echo/
          /auth-echo/test
          /auth-echo-test
          /no-auth
          http://example.org/auth-echo
          http://example.org/auth-echo/
          http://example.org/auth-echo/test
          http://example.org/auth-echo-test
          http://example.org/no-auth
        ].each do |path|
          stub.get(path) do |env|
            [200, {}, env[:request_headers]['Authorization'] || '']
          end
        end
      end
    end
  end

  def test_basic_middleware_adds_basic_header
    response = conn { |b| b.request :basic_auth, 'aladdin', 'opensesame' }.get('/auth-echo')
    assert_equal 'Basic YWxhZGRpbjpvcGVuc2VzYW1l', response.body
  end

  def test_basic_middleware_adds_basic_header_only_for_specified_urls
    c = conn { |b|
      b.request :basic_auth, 'aladdin', 'opensesame', 'http://example.net/auth-echo'
      b.request :basic_auth, 'aladdin', 'nosesame',   'http://example.org/auth-echo'
    }
    assert_equal 'Basic YWxhZGRpbjpvcGVuc2VzYW1l', c.get('/auth-echo').body
    assert_equal 'Basic YWxhZGRpbjpvcGVuc2VzYW1l', c.get('/auth-echo/').body
    assert_equal 'Basic YWxhZGRpbjpvcGVuc2VzYW1l', c.get('/auth-echo/test').body
    assert_equal '',                               c.get('/auth-echo-test').body
    assert_equal '',                               c.get('/no-auth').body
    assert_equal 'Basic YWxhZGRpbjpub3Nlc2FtZQ==', c.get('http://example.org/auth-echo').body
    assert_equal 'Basic YWxhZGRpbjpub3Nlc2FtZQ==', c.get('http://example.org/auth-echo/').body
    assert_equal 'Basic YWxhZGRpbjpub3Nlc2FtZQ==', c.get('http://example.org/auth-echo/test').body
    assert_equal '',                               c.get('http://example.org/auth-echo-test').body
    assert_equal '',                               c.get('http://example.org/no-auth').body

    c = conn { |b|
      b.request :basic_auth, 'aladdin', 'opensesame', 'http://example.net/auth-echo/'
      b.request :basic_auth, 'aladdin', 'nosesame',   'http://example.org/auth-echo/'
    }
    assert_equal '',                               c.get('/auth-echo').body
    assert_equal 'Basic YWxhZGRpbjpvcGVuc2VzYW1l', c.get('/auth-echo/').body
    assert_equal 'Basic YWxhZGRpbjpvcGVuc2VzYW1l', c.get('/auth-echo/test').body
    assert_equal '',                               c.get('/auth-echo-test').body
    assert_equal '',                               c.get('/no-auth').body
    assert_equal '',                               c.get('http://example.org/auth-echo').body
    assert_equal 'Basic YWxhZGRpbjpub3Nlc2FtZQ==', c.get('http://example.org/auth-echo/').body
    assert_equal 'Basic YWxhZGRpbjpub3Nlc2FtZQ==', c.get('http://example.org/auth-echo/test').body
    assert_equal '',                               c.get('http://example.org/auth-echo-test').body
    assert_equal '',                               c.get('http://example.org/no-auth').body

    c = conn { |b|
      b.request :basic_auth, 'aladdin', 'opensesame', 'http://example.net'
      b.request :basic_auth, 'aladdin', 'nosesame',   'http://example.org'
    }
    assert_equal 'Basic YWxhZGRpbjpvcGVuc2VzYW1l', c.get('/auth-echo').body
    assert_equal 'Basic YWxhZGRpbjpvcGVuc2VzYW1l', c.get('/auth-echo/').body
    assert_equal 'Basic YWxhZGRpbjpvcGVuc2VzYW1l', c.get('/auth-echo/test').body
    assert_equal 'Basic YWxhZGRpbjpvcGVuc2VzYW1l', c.get('/auth-echo-test').body
    assert_equal 'Basic YWxhZGRpbjpvcGVuc2VzYW1l', c.get('/no-auth').body
    assert_equal 'Basic YWxhZGRpbjpub3Nlc2FtZQ==', c.get('http://example.org/auth-echo').body
    assert_equal 'Basic YWxhZGRpbjpub3Nlc2FtZQ==', c.get('http://example.org/auth-echo/').body
    assert_equal 'Basic YWxhZGRpbjpub3Nlc2FtZQ==', c.get('http://example.org/auth-echo/test').body
    assert_equal 'Basic YWxhZGRpbjpub3Nlc2FtZQ==', c.get('http://example.org/auth-echo-test').body
    assert_equal 'Basic YWxhZGRpbjpub3Nlc2FtZQ==', c.get('http://example.org/no-auth').body
  end

  def test_basic_middleware_adds_basic_header_correctly_with_long_values
    response = conn { |b| b.request :basic_auth, 'A' * 255, '' }.get('/auth-echo')
    assert_equal "Basic #{'QUFB' * 85}Og==", response.body
  end

  def test_basic_middleware_does_not_interfere_with_existing_authorization
    response = conn { |b| b.request :basic_auth, 'aladdin', 'opensesame' }.
      get('/auth-echo', nil, :authorization => 'Token token="bar"')
    assert_equal 'Token token="bar"', response.body
  end

  def test_token_middleware_adds_token_header
    response = conn { |b| b.request :token_auth, 'quux' }.get('/auth-echo')
    assert_equal 'Token token="quux"', response.body
  end

  def test_token_middleware_includes_other_values_if_provided
    response = conn { |b|
      b.request :token_auth, 'baz', :foo => 42
    }.get('/auth-echo')
    assert_match(/^Token /, response.body)
    assert_match(/token="baz"/, response.body)
    assert_match(/foo="42"/, response.body)
  end

  def test_token_middleware_does_not_interfere_with_existing_authorization
    response = conn { |b| b.request :token_auth, 'quux' }.
      get('/auth-echo', nil, :authorization => 'Token token="bar"')
    assert_equal 'Token token="bar"', response.body
  end

  def test_authorization_middleware_with_string
    response = conn { |b|
      b.request :authorization, 'custom', 'abc def'
    }.get('/auth-echo')
    assert_match(/^custom abc def$/, response.body)
  end

  def test_authorization_middleware_with_hash
    response = conn { |b|
      b.request :authorization, 'baz', :foo => 42
    }.get('/auth-echo')
    assert_match(/^baz /, response.body)
    assert_match(/foo="42"/, response.body)
  end
end
