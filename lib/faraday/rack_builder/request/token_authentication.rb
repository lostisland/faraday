require File.expand_path("../authorization", __FILE__)

module Faraday
  class RackBuilder::Request::TokenAuthentication < RackBuilder::Request::Authorization
    # Public
    def self.header(token, options = nil)
      options ||= {}
      options[:token] = token
      super(:Token, options)
    end

    def initialize(app, token, options = nil)
      super(app, token, options)
    end
  end
end

