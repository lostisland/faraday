# frozen_string_literal: true

# This module marks an Adapter as supporting connection pooling.
module ConnectionPooling
  def self.included(base)
    base.extend(ClassMethods)
  end

  # Class methods injected into the class including this module.
  module ClassMethods
    attr_accessor :supports_pooling

    def inherited(subclass)
      super
      subclass.supports_pooling = supports_pooling
    end
  end

  attr_reader :pool

  MISSING_CONNECTION_ERROR = 'You need to define a `connection` method' \
    'in order to support connection pooling!'

  # Initializes the connection pool.
  #
  # @param opts [Hash] the options to pass to `ConnectionPool` initializer.
  def initialize_pool(opts = {})
    ensure_connection_defined!
    @pool = ConnectionPool.new(opts, &method(:connection))
  end

  # Checks if `connection` method exists and raises an error otherwise.
  def ensure_connection_defined!
    return if self.class.method_defined?(:connection)

    raise NoMethodError, MISSING_CONNECTION_ERROR
  end
end
