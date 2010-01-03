require 'rubygems'
require 'sinatra'

get '/hello_world' do
  'hello world'
end

get '/json' do
  "[1,2,3]"
end

get '/params' do
  %(params[:a] == #{params[:a]})
end

get "/headers" do
  %(env[HTTP_X_TEST] == #{env["HTTP_X_TEST"]})
end