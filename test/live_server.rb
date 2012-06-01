require 'sinatra/base'

class FaradayTestServer < Sinatra::Base
  set :logging => false,
      :show_exceptions => false

  [:get, :post, :put, :patch, :delete, :options].each do |method|
    send(method, '/echo') do
      kind = request.request_method.downcase
      out = kind.dup
      out << ' ?' << request.GET.inspect if request.GET.any?
      out << ' ' << request.POST.inspect if request.POST.any?

      content_type 'text/plain'
      return out
    end
  end

  get '/echo_header' do
    header = "HTTP_#{params[:name].tr('-', '_').upcase}"
    request.env.fetch(header) { 'NONE' }
  end

  post '/file' do
    if params[:uploaded_file].respond_to? :each_key
      "file %s %s" % [
        params[:uploaded_file][:filename],
        params[:uploaded_file][:type]]
    else
      status 400
    end
  end

  get '/multi' do
    [200, { 'Set-Cookie' => 'one, two' }, '']
  end

  get '/who-am-i' do
    request.env['REMOTE_ADDR']
  end

  get '/slow' do
    sleep 10
    [200, {}, 'ok']
  end

  get '/ssl' do
    "ssl #{request.secure?}"
  end

  error do |e|
    "#{e.class}\n#{e.to_s}\n#{e.backtrace.join("\n")}"
  end
end

if $0 == __FILE__
  options = {
    :Port => FaradayTestServer.port
  }

  if (ENV['LIVE'] || '').index('https') == 0
    require 'webrick/https'

    key     = OpenSSL::PKey::RSA.new(File.open(File.expand_path("../../faraday.cert.key", __FILE__)).read)
    cert    = OpenSSL::X509::Certificate.new(File.open(File.expand_path("../../faraday.cert.crt", __FILE__)).read)
    options = {
      :SSLEnable       => true,
      :SSLPrivateKey   => key,
      :SSLCertificate  => cert,
      :SSLVerifyClient => OpenSSL::SSL::VERIFY_PEER
    }.merge(options)
  end

  Rack::Handler::WEBrick.run(FaradayTestServer, options) do |server|
    [:INT, :TERM].each { |sig| trap(sig) { server.stop } }
  end
end

