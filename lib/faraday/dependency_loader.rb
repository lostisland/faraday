# frozen_string_literal: true

module Faraday
  module DependencyLoader
    attr_accessor :load_error
    private :load_error=

    # Executes a block which should try to require and reference dependent libraries
    def dependency(lib = nil)
      lib ? require(lib) : yield
    rescue LoadError, NameError => error
      self.load_error = error
    end

    def new(*)
      raise "missing dependency for #{self}: #{load_error.message}" unless loaded?

      super
    end

    def loaded?
      load_error.nil?
    end

    def inherited(subclass)
      super
      subclass.send(:load_error=, load_error)
    end
  end
end
