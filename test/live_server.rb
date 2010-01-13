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

get '/hello' do
  "hello #{params[:name]}"
end

post '/echo_name' do
  params[:name].inspect
end

put '/echo_name' do
  params[:name].inspect
end

delete '/delete_with_json' do
  %/{"deleted":true}/
end

delete '/delete_with_params' do
  params[:deleted]
end
