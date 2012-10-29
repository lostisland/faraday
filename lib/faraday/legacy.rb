require File.expand_path("..", __FILE__)

module Faraday
  require_libs 'rack_builder', 'autoload'
  self.default_builder_class = RackBuilder
end

