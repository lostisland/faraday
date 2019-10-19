# frozen_string_literal: true

RSpec.shared_examples 'ProxySelector::Nil' do |proxy_sel|
  it 'is the right type' do
    expect(proxy_sel).to be_a(Faraday::ProxySelector::Nil)
  end

  it 'returns no proxy for http url' do
    expect(proxy_sel.proxy_for_url(http_request_url)).to be_nil
    expect(proxy_sel.proxy_for(http_request_uri)).to be_nil
  end

  it 'returns no proxy for https url' do
    expect(proxy_sel.proxy_for_url(https_request_url)).to be_nil
    expect(proxy_sel.proxy_for(https_request_uri)).to be_nil
  end

  it 'doesnt use proxy for http url' do
    expect(proxy_sel.use_for_url?(http_request_url)).to eq(false)
    expect(proxy_sel.use_for?(http_request_uri)).to eq(false)
  end

  it 'doesnt use proxy for https url' do
    expect(proxy_sel.use_for_url?(https_request_url)).to eq(false)
    expect(proxy_sel.use_for?(https_request_uri)).to eq(false)
  end
end

RSpec.shared_examples 'ProxySelector::Single' do |proxy_sel, expected_user, expected_pass|
  it 'is the right type' do
    expect(proxy_sel).to be_a(Faraday::ProxySelector::Single)
  end

  it 'fetches proxy for http url' do
    proxy = proxy_sel.proxy_for(http_request_uri)
    expect(proxy_sel.proxy_for_url(http_request_url)).to eq(proxy)
    expect(proxy).not_to be_nil
    expect(proxy.host).to eq('proxy.com')
    expect(proxy.user).to eq(expected_user)
    expect(proxy.password).to eq(expected_pass)
  end

  it 'fetches proxy for https url' do
    proxy = proxy_sel.proxy_for(https_request_uri)
    expect(proxy_sel.proxy_for_url(https_request_url)).to eq(proxy)
    expect(proxy).not_to be_nil
    expect(proxy.host).to eq('proxy.com')
    expect(proxy.user).to eq(expected_user)
    expect(proxy.password).to eq(expected_pass)
  end

  it 'uses proxy for http url' do
    expect(proxy_sel.use_for_url?(http_request_url)).to eq(true)
    expect(proxy_sel.use_for?(http_request_uri)).to eq(true)
  end

  it 'uses proxy for https url' do
    expect(proxy_sel.use_for_url?(https_request_url)).to eq(true)
    expect(proxy_sel.use_for?(https_request_uri)).to eq(true)
  end
end

RSpec.describe Faraday::ProxySelector do
  let(:http_request_url) { 'http://http.example.com' }
  let(:https_request_url) { 'https://https.example.com' }
  let(:http_request_uri) { Faraday::Utils.URI(http_request_url) }
  let(:https_request_uri) { Faraday::Utils.URI(https_request_url) }

  context '#proxy_with_env with explicit hash' do
    let(:proxy_url) { '://example.com' }

    http_keys = Faraday::ProxySelector::Environment::HTTP_PROXY_KEYS
    https_keys = Faraday::ProxySelector::Environment::HTTPS_PROXY_KEYS
    http_keys.each do |http|
      it "parses #{http}" do
        selector = Faraday.proxy_with_env(
          http => 'http' + proxy_url
        )
        expect(selector.http_proxy.scheme).to eq('http')
        expect(selector.http_proxy.host).to eq('example.com')
      end

      https_keys.each do |https|
        it "parses #{https}" do
          selector = Faraday.proxy_with_env(
            https => 'https' + proxy_url
          )
          expect(selector.https_proxy.scheme).to eq('https')
          expect(selector.https_proxy.host).to eq('example.com')
        end

        it "parses #{http} & #{https}" do
          selector = Faraday.proxy_with_env(
            http => 'http' + proxy_url,
            https => 'https' + proxy_url
          )
          expect(selector.http_proxy.scheme).to eq('http')
          expect(selector.http_proxy.host).to eq('example.com')
          expect(selector.https_proxy.scheme).to eq('https')
          expect(selector.https_proxy.host).to eq('example.com')
        end
      end
    end
  end

  context '#proxy_with_env with env disabled' do
    @ignore_env_proxy = Faraday.ignore_env_proxy
    after { Faraday.ignore_env_proxy = @ignore_env_proxy }
    Faraday.ignore_env_proxy = true
    proxy = Faraday.proxy_with_env(nil)
    include_examples 'ProxySelector::Nil', proxy
  end

  context '#proxy_to_url with invalid scheme' do
    proxy_sel = Faraday.proxy_to_url('file://proxy.com')

    it 'is the right type' do
      expect(proxy_sel).to be_a(Faraday::ProxySelector::Single)
    end

    it 'has invalid proxy' do
      proxy = proxy_sel.proxy_for(http_request_uri)
      expect(proxy).not_to be_nil
      expect(proxy.host).to eq('file')
    end
  end

  context '#proxy_to with invalid scheme' do
    it 'raises' do
      expect { Faraday.proxy_to(Faraday::Utils.URI('file://proxy.com')) }
        .to raise_error(ArgumentError)
    end
  end

  context '#proxy_to_url without user auth' do
    proxy = Faraday.proxy_to_url('http://proxy.com')
    include_examples 'ProxySelector::Single', proxy, nil, nil
  end

  context '#proxy_to_url without scheme' do
    proxy = Faraday.proxy_to_url('proxy.com')
    include_examples 'ProxySelector::Single', proxy, nil, nil
  end

  context '#proxy_to_url with user auth in proxy url' do
    proxy = Faraday.proxy_to_url('http://u%3A1:p%3A2@proxy.com')
    include_examples 'ProxySelector::Single', proxy, 'u:1', 'p:2'
  end

  context '#proxy_to_url with explicit user auth' do
    proxy = Faraday.proxy_to_url('http://proxy.com',
                                 user: 'u:1', password: 'p:2')
    include_examples 'ProxySelector::Single', proxy, 'u:1', 'p:2'
  end
end

context Faraday::ProxySelector::Environment do
  # https://github.com/golang/net/blob/da9a3fd4c5820e74b24a6cb7fb438dc9b0dd377c/http/httpproxy/proxy_test.go#L22
  context '#proxy_for_url' do
    # [ env, req_url, expected_proxy ]
    [
      [{ http_proxy: '127.0.0.1:8080' }, nil,
       'http://127.0.0.1:8080'],
      [{ http_proxy: 'cache.corp.example.com:1234' }, nil,
       'http://cache.corp.example.com:1234'],
      [{ http_proxy: 'cache.corp.example.com' }, nil,
       'http://cache.corp.example.com'],
      [{ http_proxy: 'https://cache.corp.example.com' }, nil,
       'https://cache.corp.example.com'],
      [{ http_proxy: 'http://127.0.0.1:8080' }, nil,
       'http://127.0.0.1:8080'],
      [{ http_proxy: 'https://127.0.0.1:8080' }, nil,
       'https://127.0.0.1:8080'],
      [{ http_proxy: 'socks5://127.0.0.1' }, nil,
       'socks5://127.0.0.1'],
      # Don't use secure for http
      [{ http_proxy: 'http.proxy.tld', https_proxy: 'secure.proxy.tld' },
       'http://insecure.tld/', 'http://http.proxy.tld'],
      # Use secure for https.
      [{ http_proxy: 'http.proxy.tld', https_proxy: 'secure.proxy.tld' },
       'https://secure.tld/', 'http://secure.proxy.tld'],
      [{ http_proxy: 'http.proxy.tld', https_proxy: 'https://secure.proxy.tld' },
       'https://secure.tld/', 'https://secure.proxy.tld'],
      [{ no_proxy: 'example.com', http_proxy: 'proxy' }, nil, nil],
      [{ no_proxy: '.example.com', http_proxy: 'proxy' }, nil,
       'http://proxy'],
      [{ no_proxy: 'ample.com', http_proxy: 'proxy' }, nil, 'http://proxy'],
      [{ no_proxy: 'example.com', http_proxy: 'proxy' },
       'http://foo.example.com/', nil],
      [{ no_proxy: '.foo.com', http_proxy: 'proxy' }, nil, 'http://proxy']
    ].each do |(env, req_url, expected_proxy)|
      it "expects#{" req url #{req_url} to have" if req_url} proxy #{expected_proxy.inspect} for #{env.inspect}" do
        selector = Faraday.proxy_with_env(env)
        proxy = selector.proxy_for_url(req_url || 'http://example.com')
        if expected_proxy
          expect(proxy.uri.to_s).to eq(expected_proxy)
        else
          expect(proxy).to be_nil
        end
      end
    end
  end

  # https://github.com/golang/net/blob/da9a3fd4c5820e74b24a6cb7fb438dc9b0dd377c/http/httpproxy/proxy_test.go#L261
  context '#use_for_url?' do
    no_proxy_tests = [
      # Never proxy localhost:
      ['localhost', false],
      ['127.0.0.1', false],
      ['127.0.0.2', false],
      ['[::1]', false],
      ['[::2]', true], # not a loopback address

      ['192.168.1.1', false],                # matches exact IPv4
      ['192.168.1.2', true],                 # ports do not match
      ['192.168.1.3', false],                # matches exact IPv4:port
      ['192.168.1.4', true],                 # no match
      ['10.0.0.2', false],                   # matches IPv4/CIDR
      ['[2001:db8::52:0:1]', false],         # matches exact IPv6
      ['[2001:db8::52:0:2]', true],          # no match
      ['[2001:db8::52:0:2]:443', false],     # matches explicit [IPv6]:port
      ['[2001:db8::52:0:3]', false],         # matches exact [IPv6]:port
      ['[2002:db8:a::123]', false],          # matches IPv6/CIDR
      ['[fe80::424b:c8be:1643:a1b6]', true], # no match

      ['barbaz.net', true],          # does not match as .barbaz.net
      ['www.barbaz.net', false],     # does match as .barbaz.net
      ['foobar.com', false],         # does match as foobar.com
      ['www.foobar.com', false],     # match because NO_PROXY includes 'foobar.com'
      ['foofoobar.com', true],       # not match as a part of foobar.com
      ['baz.com', true],             # not match as a part of barbaz.com
      ['localhost.net', true],       # not match as suffix of address
      ['local.localhost', true],     # not match as prefix as address
      ['barbarbaz.net', true],       # not match, wrong domain
      ['wildcard.io', true],         # does not match as *.wildcard.io
      ['nested.wildcard.io', false], # match as *.wildcard.io
      ['awildcard.io', true]         # not a match because of '*'
    ]

    context '(full no_proxy example)' do
      proxy = Faraday.proxy_with_env(
        no_proxy: 'foobar.com, .barbaz.net, *.wildcard.io, 192.168.1.1, 192.168.1.2:81, 192.168.1.3:80, 10.0.0.0/30, 2001:db8::52:0:1, [2001:db8::52:0:2]:443, [2001:db8::52:0:3]:80, 2002:db8:a::45/64'
      )

      no_proxy_tests.each do |(host, matches)|
        it "#{matches ? :allows : :forbids} proxy for #{host}" do
          expect(proxy.use_for_url?("http://#{host}/test")).to eq(matches)
        end
      end
    end

    context '(invalid no_proxy)' do
      it 'forbids proxy' do
        proxy = Faraday.proxy_with_env(no_proxy: ':1')
        expect(proxy.use_for_url?('http://example.com')).to eq(true)
      end
    end

    context '(no_proxy=*)' do
      proxy = Faraday.proxy_with_env(no_proxy: 'baz.com, *')

      no_proxy_tests.each do |(host, _)|
        it "forbids proxy for #{host}" do
          expect(proxy.use_for_url?("http://#{host}/test")).to eq(false)
        end
      end
    end
  end
end
