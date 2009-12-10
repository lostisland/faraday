require 'rubygems'
require 'sinatra'

get '/hello_world' do
  'hello world'
end

get '/json' do
  "[1,2,3]"
end