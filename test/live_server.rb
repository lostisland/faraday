require 'rubygems'
require 'sinatra'

get '/hello_world' do
  'hello world'
end

get '/json' do
  "[1,2,3]"
end

post '/hello' do
  "hello #{params[:name]}"
end

post '/echo_name' do
  %/{"name":#{params[:name].inspect}}/
end
