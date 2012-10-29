require File.expand_path("..", __FILE__) unless Object.const_defined?(:Faraday)

module Faraday
  # Makes every attempt to provide compatibility with Faraday 0.8.x
  LEGACY = true

  require_libs 'rack_builder', 'autoload'
  self.default_builder_class = RackBuilder

  Response::Middleware = RackBuilder::Response::Middleware
  Adapter = RackBuilder::Adapter
  Middleware = RackBuilder::Middleware
  Builder = RackBuilder
  Response.send :include, RackBuilder::Response
  Request.send :include, RackBuilder::Request
end

