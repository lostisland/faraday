require File.expand_path("..", __FILE__)

module Faraday
  require_libs 'rack_builder', 'autoload'
  self.default_builder_class = RackBuilder

  Response::Middleware = RackBuilder::Response::Middleware
  Adapter = RackBuilder::Adapter
  Middleware = RackBuilder::Middleware
  Builder = RackBuilder
  Response.send :include, RackBuilder::Response
  Request.send :include, RackBuilder::Request
end

