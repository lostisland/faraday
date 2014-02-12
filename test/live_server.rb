require 'sinatra/base'

module Faraday
class LiveServer < Sinatra::Base
  set :environment, :test
  disable :logging
  disable :protection

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
      "file %s %s %d" % [
        params[:uploaded_file][:filename],
        params[:uploaded_file][:type],
        params[:uploaded_file][:tempfile].size
      ]
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

  get '/204' do
    status 204 # no content
  end

  get '/ssl' do
    request.secure?.to_s
  end

  get '/basic-auth/:user/:password' do
    required_credentials = [params[:user], params[:password]]
    auth = Rack::Auth::Basic::Request.new(request.env)

    if auth.provided? && auth.basic? && auth.credentials == required_credentials
      halt 200, "Authorized\n"
    else
      halt 401, "Not authorized\n"
    end
  end

  error do |e|
    "#{e.class}\n#{e.to_s}\n#{e.backtrace.join("\n")}"
  end
end
end

if $0 == __FILE__
  Faraday::LiveServer.run!
end
