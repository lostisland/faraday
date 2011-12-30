require 'sinatra'
set :logging, false

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

get '/hello_world' do
  'hello world'
end

get '/json' do
  content_type 'application/json'
  "[1,2,3]"
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

[:get, :post].each do |method|
  send(method, '/hello') do
    "hello #{params[:name]}"
  end
end

%w[POST PUT PATCH].each do |http_method|
  settings.send(:route, http_method, '/echo_name') do
    params[:name].inspect
  end
end

options '/options' do
  'hi'
end

delete '/delete_with_json' do
  %/{"deleted":true}/
end

get '/multi' do
  [200, { 'Set-Cookie' => 'one, two' }, '']
end

get '/slow' do
  sleep 10
  [200, {}, 'ok']
end
