module Faraday
  class Middleware
    class << self
      attr_accessor :load_error
    end

    # Executes a block which should try to require and reference dependent libraries
    def self.dependency(lib = nil)
      lib ? require(lib) : yield
    rescue LoadError, NameError => error
      self.load_error = error
    end

    def self.loaded?
      @load_error.nil?
    end

    def initialize(app = nil)
      @app = app
    end
  end
end
